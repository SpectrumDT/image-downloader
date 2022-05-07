Param([Parameter(Mandatory=$true)][string]$path)

if ($path.StartsWith("http")){
    Write-Host "URI: $uri"
    If (-not (Test-Path ("./temp"))){ New-Item -ItemType Directory "./temp" }
    $localPage = "./temp/page.html"
    Write-Host "Downloading..."
    Invoke-WebRequest -Uri $uri -OutFile $localPage
    Write-Host "Downloaded to: $localPage"
} else {
    $localPage = $path
}
$lines = Get-Content $localPage
Write-Host "File is $($lines.Length) lines long"

Function Get-Sections ($lines) {
    Function New-Section ($heading, $hrefs) {
        return @{
            Heading = $heading
            Hrefs = $hrefs
        }
    }
    Function Save-Section ($heading, $hrefs) {
        $section = New-Section $heading $hrefs
        #Write-Host "Created section: $section"

        $sections.Add($section)
        #Write-Host "Stored section: $($section.Heading) with count: $($section.Hrefs.Count)"
    }
    Function Get-Heading ($line) {
        return $line.Replace("</b></p>","").Replace("<p><b>","").Replace("  <b>","").Replace(" </b><b>","")
    }

    $sections = [System.Collections.Generic.List[object]]::new()

    $heading = ""
    $hrefs = [System.Collections.Generic.List[string]]::new()
    $lines | ForEach-Object {
        $line = $_
        If ($line.EndsWith("</b></p>")) {
            if ($hrefs.Count -gt 0) {
                Save-Section $heading $hrefs
                $hrefs = [System.Collections.Generic.List[string]]::new()
            }
            $heading = Get-Heading $line
            #Write-Host "Section: $heading"
        }
        If ($line.Contains("href")) {
            $match = $line -match 'href=\"(.+)\"><img'
            #Write-Host "Match: $($Matches.1)"
            $hrefs.Add($Matches.1)
        }
    }
    Save-Section $heading $hrefs # Store final section.
    Write-Host "Found $($sections.Count) sections"
    return $sections
}

$sections = Get-Sections $lines

$sections | ForEach-Object {
    $section = $_
    $heading = $section.Heading
    Write-Host "Section: '$heading' with count: $($section.Hrefs.Count)"
    $subfolderPath = "./$heading"
    If (-not (Test-Path $subfolderPath)) { New-Item -ItemType Directory $subfolderPath }
    $section.Hrefs | ForEach-Object {
        $uri = $_
        $fileName = Split-Path $uri -Leaf
        $outPath = "$subfolderPath/$fileName"
        If (-not (Test-Path $outPath)) {
            Write-Host "  Downloading: $uri"
            Invoke-WebRequest -Uri $uri -OutFile $outPath
            Write-Host "  Downloaded: $uri"
        }
    }
}