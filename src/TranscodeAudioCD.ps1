function ConvertFromDefaultANSIPageToUTF8 {

    <#
    .DESCRIPTION
    Converts the input text (string) via the default encoding to UTF8 encoding.
    #>

    param(
        # Text to convert.
        [string]$text
    )

    return [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes($text))
}

function GetFreeLocalPort {

    <#
    .DESCRIPTION
    Tries to get a free local port on the machine.
    #>

    $usedLocalPorts = (Get-NetTCPConnection).LocalPort + (Get-NetUDPEndpoint).LocalPort
    return 5000..60000 | where { $usedLocalPorts -notcontains $_ } | select -first 1
}

function LoginHeader {

    <#
    .DESCRIPTION
    Creates a HTTP header with the login details for basic authentication scheme.
    #>

    param(
        # User name for basic authentication.
        [string]$username,
        # Credentials for user.
        [string]$pw
    )

    $pair = "$($username):$($pw)"
    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
    $Headers = @{
        Authorization = "Basic $encodedCreds"
    }
    return $Headers
}

function StopVlcInstances {

    Get-Process -Name "vlc" -ErrorAction Ignore | foreach { Stop-Process -Id $_.Id }
}

function GetAudioTrackTitles {

    <#
    .DESCRIPTION
    Determines the list of track names by loading the audio CD in VLC with the HTTP interface (no GUI) and meta data lookup.
    Then obtains the playlist via the HTTP API.
    #>

    param(
        # The device that holds the audio CD, e.g. 'D:' drive.
        [string] $AudioDevice,
        # The path to the VLC executable (vlc.exe).
        [string] $VlcPath = 'C:\Program Files\VideoLAN\VLC\vlc.exe'
    )

    $portNr = GetFreeLocalPort
    $passPhrase = "$(New-Guid)"

    & $VlcPath -I http --http-host=127.0.0.1 --http-port=$portNr --http-password=$passPhrase --metadata-network-access --start-paused cdda:///$AudioDevice

    $nrOfRequests = 0
    $maxRequests = 20
    $delayInMs = 500
    do {
        Start-Sleep -Milliseconds $delayInMs
        $nrOfRequests += 1
        $playlistXml = Invoke-RestMethod -Uri "http://127.0.0.1:$portNr/requests/playlist.xml" -Headers $(LoginHeader "" $passPhrase)
        $tracksXml = if($playlistXml) { $playlistXml.SelectNodes("//leaf") } else {@()}
    } while (($nrOfRequests -le $maxRequests) -and ($tracksXml.Count -le 1))

    if($nrOfRequests -gt $maxRequests) {
        throw "Failed to retrieve playlist via HTTP interface within $($maxRequests * $delayInMs)ms. No audio CD in device, device not connected or invalid device specified ?"
    }

    StopVlcInstances

    return $tracksXml | foreach { $_.name }
}

function TranscodeTracks {

    <#
    .DESCRIPTION
    Transcodes one track at the time to MP3. Uses no interfaces (no GUI).
    #>

    param(
        # List of track names (in order i.e. 1...last).
        [string[]] $TrackList,
        # The device that holds the audio CD, e.g. 'D:' drive.
        [string]   $AudioDevice,
        # Directory to which the transcoded tracks are written to.
        [string]   $OutputDir,
        # The path to the VLC executable (vlc.exe).
        [string]   $VlcPath = 'C:\Program Files\VideoLAN\VLC\vlc.exe'
    )

    1..$TrackList.Count | foreach { 
        $nr = $_
        $name = (ConvertFromDefaultANSIPageToUTF8 $TrackList[$nr-1])
        $name = "$nr $name" -replace '"', ""
        Write-Host "- Transcoding track $nr to '$OutputDir$name.mp3'" 
        & $VlcPath -v -I dummy --sout="#transcode{acodec=mp3,ab=192,channels=2}:std{access=file,mux=raw,dst=$OutputDir$name.mp3}" cdda:///$AudioDevice --cdda-track="$nr" vlc://quit
        Wait-Process -Name "vlc"
    }
}

function TranscodeAudioCD {

    <#
    .DESCRIPTION
    TranscodeAudioCD transcodes all tracks on an audio CD to MP3 files on the disk.
    It tries to obtain the track names via meta data support from VLC, and uses this as the file name when writing to disk.
    Notes:
    - Stops all VLC process prior to transcoding to prevent potential conflicts accessing the same media.
    - Runs instances of VLC process in GUI-less modes to help with the transcoding. 

    .EXAMPLE
    PS> TranscodeAudioCD "D:" "C:/Temp/"
    #>

    param(
        # The device that holds the audio CD, e.g. 'D:' drive. Is combined to MRL: cdda:///$AudioDevice.
        [string] $AudioDevice,
        # Absolute path to directory to which the transcoded tracks are written to.
        [string] $OutputDir,
        # The path to the VLC executable (vlc.exe).
        [string] $VlcPath = 'C:\Program Files\VideoLAN\VLC\vlc.exe'
    )

    try {

        $watch = New-Object -TypeName System.Diagnostics.Stopwatch
        $watch.Start()

        Write-Host "Start transcoding audio CD.."

        # Stop any VLC process to not have potential conflicts
        StopVlcInstances

        $tracks = GetAudioTrackTitles $AudioDevice $VlcPath

        Write-Host "Audio CD has $($tracks.Count) tracks"

        TranscodeTracks $tracks $AudioDevice $OutputDir $VlcPath

        $watch.Stop()
        Write-Host "Transcoding audio CD completed. Took $($watch.ElapsedMilliseconds/1000)sec."
    }
    catch {
        Write-Error "Unexpected error occurred: $_"
    }
    finally {
        # Ensure there is no lingering process around
        StopVlcInstances
    }
}

# Transcode example
#TranscodeAudioCD "D:" "C:/Temp/"