# StringSimilarity.psm

<# .DESCRIPTION
    Custom string fuzzy matching on a scale of [0, 1]
    0 => no similarity, 1 => exact match
    Loosely based on Jaro similarity:
    https://en.wikipedia.org/wiki/Jaro–Winkler_distance

#>
<# .EXAMPLE

StringCompare -S1 "locking" `
    -S2 "goose" `
    -Verbose $True 
=> 0.448

StringCompare -S1 "227 King St. South Waterloo ON N2J 4C5" `
    -S2 "227 King Street S Waterloo, ON N2J4C5" `
    -Verbose $True `
    -Strip @(' ') `
    -KeepCase $False `
    -IgnoreShort 4
=> 0.902 

StringCompare -S1 "227 King St. South Waterloo ON N2J 4C5" `
    -S2 "227 King Street S Waterloo, ON N2J4C5" `
    -Verbose $True `
    -Strip @(' ', '.') `
    -KeepCase $False `
    -IgnoreShort 4
=> 0.911

StringCompare -S1 "227 King St. South Waterloo ON N2J 4C5" `
    -S2 "227 King Street S Waterloo, ON N2J4C5" `
    -Verbose $True `
    -Strip @(' ', '.', ',') `
    -KeepCase $False `
    -IgnoreShort 4
=> 0.921

#>
function StringCompare {
    param(
        [String] $S1,
        [String] $S2,
        [Boolean] $Verbose=$False,
        [String[]] $Strip=@(" "),
        [Boolean] $KeepCase=$False,
        [Int] $IgnoreShort=4
    )

    # Pre-Processing
    # remove spaces by default, allows arbitrary strings to be stripped away
    if($Verbose) {
        Write-Host "Stripping characters: "
        foreach ($s in $Strip){
            Write-Host "'$s'"
        }
    }
    if($Strip.length -gt 0) {
        foreach ($s in $Strip) {
            $S1 = $S1.Replace($s, '')
            $S2 = $S2.Replace($s, '')
        }
    }
    [Int]$L1, [Int]$L2 = $S1.length, $S2.length
    if ($L1 -lt $L2) { # assert S1 is longest string, for convenience
        $S1, $S2 = $S2, $S1
        $L1, $L2 = $L2, $L1
    }
    if(-not($KeepCase)) { # case insenstive by default
        $S1, $S2 = $S1.ToUpper(), $S2.ToUpper()
    }
    if ($Verbose) { # verbose display after pre-processing
        Write-Host "$L1 - $S1"
        Write-Host "$L2 - $S2"
    }
    # short circuit exact matches after processing
    if ($S1 -eq $S2) {
        return 1
    }
    # arbitrary decision that fuzzy matching of 'short' strings
    #   is not informative
    if (($L2 -eq 0) -or ($L2 -le $IgnoreShort)) {
        if($Verbose) {Write-Host "Short string < $IgnoreShort"}
        return 0 # already tested for exact matches
    }

    # size of matching-window
        #   original uses (max length ÷ 2) - 1
        #mdist = (l1 ÷ 2) - 1
        #mdist = l1 ÷ 4 # bidirectional window needs to be smaller
        # chosen to optimize for comparison of address text
    [Int] $mdist = [Math]::floor([Math]::sqrt($L1))
    if($Verbose) {Write-Host "match distance - $mdist"}

    # order-sensitive match index of each character such that
        # (oolong, goose) has two matches [0,1], [1,2] but
        # (locking, goose) has only one match [1], [1]
    [Int[]] $m1, [Int[]] $m2 = @(), @()
    # m1 needed only for debugging

    foreach ($i in 0..($L1-1)) {
        [Int] $WindowStart = [Math]::Max(0, $i-$mdist)
        [Int] $WindowEnd = [Math]::Min($L2-1, $i+$mdist)
        if ($WindowStart -gt $L2) {
            break
        }
        foreach ($j in ($WindowStart..$WindowEnd) | Where-Object {$_ -notin $m2}) {
            if($S1[$i] -eq $S2[$j]) {
                $m1 += $i
                $m2 += $j
                break
            }
        }
    }

    [Int] $matches = $m2.length

    if($Verbose) {
        Write-Host "matches - $matches"
        Write-Host $m1
        Write-Host $m2
    }

    if($matches -eq 0) {
        return 0
    }
    elseif($matches -eq 1) {
        return [Math]::Round((1/$L1 + 1/$L2 + 1) / 3, 3)
    }
    else {
        [Int] $transposes = 0
        foreach($k in (2..$matches)) {
            $transposes += !($m2[$k-2] -lt $m2[$k-1])
        }
        if($Verbose) {Write-Host "transposes - $transposes"}
        return [Math]::Round(
            (($matches / $L1) + ($matches / $L2) + ($matches - $transposes) / $matches ) / 3, 3)
    }
}
