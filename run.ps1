function main()
{
    $WebRTCAddress = "127.0.0.1"
    $WebRTCPort = "8083"
	$IntPort = "9000"
	
	# Start WebRTCGateway Server
    $params = @{
        DisplayName = "RTSPtoWebRTC Gateway"
        Executable = "C:\opt\RTSPtoWebRTC\RTSPtoWebRTC.exe"
        WorkingDirectory = "C:\opt\RTSPtoWebRTC"
        LoadedHandlesCompleted = 121
        LoadedNPMCompleted = 13584
    }
    StartAndWaitToOpen @params

	# Start Google Chrome
    StartChrome -Address $WebRTCAddress -Port $WebRTCPort
	
	# Start IntServer
	StartIntServer -Port $IntPort
}

function StartIntServer
{
	[CMDLetBinding()]
    param
    (
		[System.Int32]$Port
	)
	
	$listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://+:$($Port)/")
    $listener.Start()

    Write-Host "IntServer started on port $Port..."

    while ($true) {
		try {
			$context = $listener.GetContext()
			$request = $context.Request
			$contentType = $request.Headers["Content-Type"]
		
			if ($contentType -eq "application/json") {
				$reader = New-Object System.IO.StreamReader($request.InputStream)
				$data = $reader.ReadToEnd()
			
				$obj = $data | ConvertFrom-Json
				if($obj.shutdown)
				{
					Write-Response -context $context -message "Shutdown process initiated machine."
					Stop-Computer -ComputerName localhost -Force
				} else {
                    Write-Response -context $context -message "This parameter is not implemented. $($data)"
                }
			}
			else {
				Write-Response -context $context -message "Received a request with an unsupported Content-Type: $contentType"
			}

			$response = $context.Response
			$response.Close()
		} catch{}
    }
}

function Write-Response
{
    [CMDLetBinding()]
    param(
        [System.Net.HttpListenerContext]$context,
        [System.String]$message
    )

    $response = $context.Response
    $response.ContentType = "text/plain"
    $response.ContentEncoding = [System.Text.Encoding]::UTF8
    $response.StatusCode = 200
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.Close()

    Write-Host $message
}

function StartAndWaitToOpen
{
    [CMDLetBinding()]
    param
    (
        [string]$Executable,
        [string]$WorkingDirectory,
		[string]$DisplayName,
        [int]$LoadedHandlesCompleted,
        [int]$LoadedNPMCompleted
    )
	
    $proc = [System.Diagnostics.Process]::new()
    $proc.StartInfo.FileName = $Executable
    $proc.StartInfo.WorkingDirectory = $WorkingDirectory
    $proc.Start()

    $pname = [System.IO.Path]::GetFileNameWithoutExtension($Executable)

    

    while($true)
    {
        $p = Get-Process -Name $pname
        Write-Host $pname
        if(($p.Handles -ge $LoadedHandlesCompleted) -and ($p.NPM -ge $LoadedNPMCompleted))
        {
            write-Host "`n > Program has been started." -ForegroundColor Cyan
            break
        } else {
            Write-Host "`r > Handles: $($p.Handles) NPM: $($p.NPM)" -NoNewline -ForegroundColor Yellow
            Start-Sleep -Milliseconds 500
        }
    }
}

function StartChrome
{
    [CMDLetBinding()]
    Param(
        [System.String]$Address,
        [System.String]$Port
    )

    $proc = [System.Diagnostics.Process]::new()
    $proc.StartInfo.FileName = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    $proc.StartInfo.Arguments = @(
        "--no-first-run"
        "--start-maximized"
        "--disable-translate"
        "--disable-infobars"
        "--disable-save-password-bubble"
        "--incognito"
        "--kiosk"
        "http://$($Address):$($Port)"
    )

    $proc.Start()
}

main
