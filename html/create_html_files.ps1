#[byte][char]'B'
# -> 66
#[byte][char]'Z'
# -> 90

foreach ($num in 66..90) {
    Copy-Item -Path "UserA.html" -Destination "User$([char]$num).html"
}