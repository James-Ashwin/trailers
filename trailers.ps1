$LogActivity = $true
$TestModeRadarr = $false
$TmdbApiKEy = "c547771cec63e614e796c428285efe48";
$YoutubeApiKey = "AIzaSyAVm2mu31T9rbB0KA94Rx08vEfty91kX48"
$YoutubeParams = @{default=[pscustomobject]@{UseOriginalMovieName=$false; SearchKeywords='Official Trailer'}}

Add-Type -AssemblyName System.Web

$MyInvocation.MyCommand.Path | Split-Path | Push-Location

$LogFolderName = "Logs"
if($LogActivity -and -not(Test-Path $LogFolderName)) {
    New-Item $LogFolderName -ItemType Directory
}
$LogFileName = Get-Date -Format FileDateTime
$LogFileName = "$LogFolderName/$LogFileName.txt"

function Log {
    param ($LogText)

    echo $LogText
    if($LogActivity) {
        $LogText >> $LogFileName
    }
}

function LogInFunction {
    param($LogText)

    Write-Information $LogText -InformationAction Continue
    if($LogActivity) {
        $LogText >> $LogFileName
    }
}

function fetchJSON {
    param($url)

    LogInFunction "Issuing web request to $url ..."
    $req = [System.Net.WebRequest]::Create("$url")

    $req.ContentType = "application/json; charset=utf-8"
    $req.Accept = "application/json"

    $resp = $req.GetResponse()
    $reader = new-object System.IO.StreamReader($resp.GetResponseStream())
    $responseJSON = $reader.ReadToEnd()

    $response = $responseJSON | ConvertFrom-Json
    return $response
}

function Get-YoutubeTrailer {
    param (
        $movieTitle, 
        $movieYear, 
        $moviePath,
        $tmdbId
    )

    $trailerFilename = "$moviePath\$movieTitle ($movieYear)-Trailer.mp4"

    $keywords = $YoutubeParams.default.SearchKeywords;
    if($TmdbApiKEy -ne 'YOUR_API_KEY' -and $tmdbId -ne '') {
        $tmdbURL = "https://api.themoviedb.org/3/movie/$($tmdbId)?api_key=$TmdbApiKEy"
        LogInFunction "Querying TMDB for details of movie #$tmdbId ..."
        $tmdbInfo = fetchJSON($tmdbURL)

        if($YoutubeParams.ContainsKey($tmdbInfo.original_language)) {
            $keywords = $YoutubeParams[$tmdbInfo.original_language].SearchKeywords
            if($YoutubeParams[$tmdbInfo.original_language].UseOriginalMovieName) {
                $movieTitle = $tmdbInfo.original_title
                LogInFunction "Using original movie title : $movieTitle"
            }
        }
    }

    $ytQuery = "$movieTitle $movieYear $keywords"
    $ytQuery = [System.Web.HTTPUtility]::UrlEncode($ytQuery)

    $ytSearchUrl = "https://youtube.googleapis.com/youtube/v3/search?part=snippet&maxResults=1&q=$ytQuery&type=video&videoDuration=short&key=$YoutubeApiKey"
    LogInFunction "Sending Youtube search request ..."
    $ytSearchResults =  fetchJSON($ytSearchUrl)
    $ytVideoId = $ytSearchResults.items[0].id.videoId

    LogInFunction "Downloading video ..."
    & .\yt-dlp.exe -o $trailerFilename https://www.youtube.com/watch?v=$ytVideoId | Out-File -FilePath $LogFileName -Append
    LogInFunction "Trailer successfully downloaded and saved to $trailerFilename"
    LogInFunction "Pausing for 15 seconds to avoid being flagged by YouTube."
    Timeout /T 15
}

if($TestModeRadarr) {
    Log "Setting TEST MODE environment"
    $Env:radarr_eventtype = "Download"
    $Env:radarr_isupgrade = "False"
    $Env:radarr_movie_path = "Z:\Movies\Ghostbusters (1984)"
    $Env:radarr_movie_title = "Ghostbusters"
    $Env:radarr_movie_year = "1984"
    $Env:radarr_movie_tmdbid = "620"
}

cls

if(Test-Path Env:radarr_eventtype) {
    Log "Script triggered from Radarr"

    if($Env:radarr_eventtype -eq "Test") {
        if($YoutubeApiKey -eq "YOUR_API_KEY") {
            Log "Please insert your Youtube API key for the script to work"
            exit 1
        }
        Log "Test successful"
    }
    
    if(($Env:radarr_eventtype -eq "Download" -and $Env:radarr_isupgrade -eq "False") -or $Env:radarr_eventtype -eq "Rename") {
        Get-YoutubeTrailer $Env:radarr_movie_title $Env:radarr_movie_year $Env:radarr_movie_path $Env:radarr_movie_tmdbid
    }
    
    exit 0
}

if($args.Count -eq 0) {
    echo "Usage : .\trailers.ps1 movies_library_root_folder"
    echo "Example: .\trailers.ps1 Z:\movies"
    exit 0
}

$libraryRoot = $args[0]
if(-not(Test-Path $libraryRoot)) {
    Log "The root folder doesn't exist"
    exit 1
}

$downloadedTrailersCount = 0
Get-ChildItem -Path $libraryRoot -Directory |
ForEach-Object {
    $alreadyHasTrailer = $false
    Get-ChildItem -LiteralPath "$($_.FullName)" -File -Exclude *part -Filter "*Trailer.*" |
    ForEach-Object {
        if($_.Extension -ne ".part") {
            $alreadyHasTrailer = $true
        }
    }

    if($alreadyHasTrailer) {
        Log "Skipping ""$($_.Name)"" as it already has a trailer"
    }
    else {
        Log "Downloading a trailer for ""$($_.Name)"" ..."
        
        $videoFile = Get-ChildItem -LiteralPath "$($_.FullName)" -File | Sort-Object Length -Descending | Select-Object BaseName -First 1
        if($videoFile.BaseName -match "(.*) \((\d{4})\)") {
            $title = $Matches.1
            $year = $Matches.2
            
            $tmdbId = '';
            if($TmdbApiKEy -ne 'YOUR_API_KEY') {
                $tmdbSearchURL = "https://api.themoviedb.org/3/search/movie?api_key=$TmdbApiKEy&query=$([System.Web.HTTPUtility]::UrlEncode($title))&year=$year"
                Log "Searching for TMDB ID : $tmdbSearchURL"
                $tmdbSearchResultsJSON = curl $tmdbSearchURL
                $tmdbSearchResults = $tmdbSearchResultsJSON | ConvertFrom-Json
                if($tmdbSearchResults.total_results -ge 1) {
                    $tmdbId = $tmdbSearchResults.results[0].id;
                }
            }

            Get-YoutubeTrailer $title $year $_.FullName $tmdbId
            $downloadedTrailersCount++
        }
        else {
            Log "Invalid name format, skipping"
        }
    }
}
Log "You succesfully downloaded $downloadedTrailersCount new trailers."
