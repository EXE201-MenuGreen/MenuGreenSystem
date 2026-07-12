# =============================================================================
# MenuGreen - PowerShell Script to execute split SQL files sequentially
# =============================================================================

# Cấu hình Database
$DbContainer = "menugreen_db"
$DbUser = "postgres"
$DbName = "MenuGreenDb"
$DbPassword = "12345"
$SeedDirName = "database"

# Đường dẫn thư mục
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$SeedDir = Join-Path $PSScriptRoot $SeedDirName

if (-not (Test-Path $SeedDir)) {
    Write-Error "Khong tim thay thu muc seed data tai: $SeedDir"
    exit 1
}

# Lấy danh sách file SQL sắp xếp theo tên
$files = Get-ChildItem -Path $SeedDir -Filter *.sql | Sort-Object Name

Write-Host "=========================================================================" -ForegroundColor Green
Write-Host "MenuGreen - Seed Data Runner" -ForegroundColor Green
Write-Host "=========================================================================" -ForegroundColor Green
Write-Host "Tim thay $($files.Count) file SQL trong thu muc '$SeedDirName'."
Write-Host ""
Write-Host "Chon phuong thuc chay:"
Write-Host "  [1] Chay tren Docker container '$DbContainer' (Khuyen nghi neu dang chay Docker)"
Write-Host "  [2] Chay bang lenh 'psql' tren may cuc bo (Yeu cau co PostgreSQL client tren Windows)"
Write-Host "  [3] Gop $($files.Count) file thanh 1 file duy nhat 'combined_seed_data.sql' de chay bang PgAdmin/DBeaver"
Write-Host "  [4] Thoat"
Write-Host ""

$choice = Read-Host "Nhap lua chon cua ban (1-4)"

if ($choice -eq "1") {
    # Kiểm tra Docker có chạy không
    $dockerCheck = docker ps --filter "name=$DbContainer" --format "{{.Names}}"
    if (-not $dockerCheck) {
        Write-Warning "Khong tim thay container '$DbContainer' dang chay. Vui long bat Docker va khoi dong container."
        $confirm = Read-Host "Ban van muon tiep tuc? (y/n)"
        if ($confirm -ne "y") { exit }
    }

    Write-Host "`nDang chay tren Docker container '$DbContainer'..." -ForegroundColor Cyan
    $count = 0
    foreach ($file in $files) {
        $count++
        Write-Host "[$count/$($files.Count)] Dang chay $($file.Name)..." -ForegroundColor Yellow
        
        # Pipe nội dung file SQL trực tiếp vao psql trong container
        Get-Content $file.FullName -Raw -Encoding UTF8 | docker exec -i $DbContainer psql -U $DbUser -d $DbName
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Loi khi chay file $($file.Name)"
            $continue = Read-Host "Ban co muon tiep tuc chay cac file con lai? (y/n)"
            if ($continue -ne "y") { break }
        }
    }
    Write-Host "`nHoan thanh import seed data tren Docker!" -ForegroundColor Green
}
elseif ($choice -eq "2") {
    # Thiết lập mật khẩu postgres tạm thời cho session và encoding UTF8
    $env:PGPASSWORD = $DbPassword
    $env:PGCLIENTENCODING = 'UTF8'
    
    # Kiểm tra và tự động tạo Database nếu chưa tồn tại
    Write-Host "`nKiem tra xem database '$DbName' da ton tai tren may cuc bo chua..." -ForegroundColor Cyan
    $dbExistsResult = psql -U $DbUser -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DbName'" 2>$null
    $dbExists = ""
    if ($dbExistsResult) {
        $dbExists = $dbExistsResult.Trim()
    }
    
    if ($dbExists -ne "1") {
        Write-Host "Database '$DbName' chua ton tai. Dang tu dong tao..." -ForegroundColor Yellow
        psql -U $DbUser -d postgres -c "CREATE DATABASE `"$DbName`";"
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Khong the tu dong tao database '$DbName'. Vui long kiem tra quyen truy cap hoac tao thu cong."
            $env:PGPASSWORD = $null
            exit 1
        }
        Write-Host "Da tao database '$DbName' thanh cong!" -ForegroundColor Green
    } else {
        Write-Host "Database '$DbName' da ton tai." -ForegroundColor Green
    }
    
    Write-Host "`nDang chay bang lenh local psql..." -ForegroundColor Cyan
    $count = 0
    foreach ($file in $files) {
        $count++
        Write-Host "[$count/$($files.Count)] Dang chay $($file.Name)..." -ForegroundColor Yellow
        
        # Chạy lệnh psql
        psql -U $DbUser -d $DbName -f $file.FullName
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Loi khi chay file $($file.Name)"
            $continue = Read-Host "Ban co muon tiep tuc chay cac file con lai? (y/n)"
            if ($continue -ne "y") { break }
        }
    }
    # Xoá mật khẩu và encoding sau khi chay
    $env:PGPASSWORD = $null
    $env:PGCLIENTENCODING = $null
    Write-Host "`nHoan thanh import seed data cuc bo!" -ForegroundColor Green
}
elseif ($choice -eq "3") {
    Write-Host "`nDang gop $($files.Count) file SQL..." -ForegroundColor Cyan
    $combinedPath = Join-Path $PSScriptRoot "combined_seed_data.sql"
    
    # Khoi tao file voi BEGIN
    $combinedContent = "BEGIN;`n`n"
    
    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8
        
        # Loại bỏ các lenh BEGIN; va COMMIT; cua tung file don le
        # de bao boc toan bo bang 1 transaction duy nhat cho toc do nhanh nhat
        $content = $content -replace "(?i)^\s*BEGIN\s*;\s*", ""
        $content = $content -replace "(?i)^\s*COMMIT\s*;\s*", ""
        
        $combinedContent += "-- ==================================================`n"
        $combinedContent += "-- Table: $($file.Name)`n"
        $combinedContent += "-- ==================================================`n"
        $combinedContent += $content + "`n`n"
    }
    
    $combinedContent += "COMMIT;"
    
    # Ghi file bang ma hoa UTF-8
    [System.IO.File]::WriteAllText($combinedPath, $combinedContent, [System.Text.Encoding]::UTF8)
    
    Write-Host "`nDa tao file gop tai: $combinedPath" -ForegroundColor Green
    Write-Host "Ban co the mo file nay bang PgAdmin, DBeaver, hoac VS Code va chay 1 lan la xong." -ForegroundColor Green
}
else {
    Write-Host "Da thoat."
}
