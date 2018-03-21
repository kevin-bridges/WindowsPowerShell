function Show-MyModules{
    $mymodulepath = $env:PSModulePath
    $mymodulepatharray = $mymodulepath.Tostring().Split("{;}");

    foreach ($item in $mymodulepatharray){
        Write-Host $item -ForegroundColor "green"
        (Get-ChildItem $item).Name
    }
    Write-Host "To show a available commands by module, run: " -ForegroundColor "green" -BackgroundColor "black"
    Write-Host "Get-Command -Module <module_name>" -ForegroundColor "green" -BackgroundColor "black"
}