Attribute VB_Name = "StringSimilarity"

Function string_similarity(ByVal s1 As String, ByVal s2 As String, Optional ByVal verbose As Boolean = False) As Double
    ' Custom string fuzzy matching on a scale of [0, 1]
    ' 0 => no similarity, 1 => exact match
    ' Empirically, random independently generated strings ~0.40 on average, similar strings >0.85
    ' Loosely based on Jaro similarity: https://en.wikipedia.org/wiki/Jaro-Winkler_distance
    
    ' originally coded Jan 2021 by Thomas Vandrus
    
    Dim strip(0) As String
    Dim L1, L2, short As Long
    Dim mdist, window_start, window_end As Long
    Dim matches, transposes As Long
    Dim i, j, k, n As Long
    Dim m1, m2, checkSet As New ArrayList 'requires Reference to mscorlib.dll
    
    strip(0) = " " ' able to strip out other characters, punctuation
    For Each s In strip
        s1 = Replace(s1, s, "")
        s2 = Replace(s2, s, "")
    Next s
    
    ' standardize case for character-by-character equality
    s1 = UCase(s1)
    s2 = UCase(s2)
    
    ' short circuit if difference was stripped and exact matching works
    If s1 = s2 Then
        string_similarity = 1
        Exit Function
    End If

    
    L1 = Len(s1)
    L2 = Len(s2)
    ' ensure s1 is always the longer string
    If L1 < L2 Then
        temp = s1
        s1 = s2
        s2 = temp
        L1 = Len(s1)
        L2 = Len(s2)
    End If
    If verbose Then Debug.Print s1 & vbNewLine & s2
    
    ' arbitrary decision that fuzzy matching of short strings
    '  is not informative
    short = 4
    If L2 = 0 Or L2 <= short Then
        If verbose Then Debug.Print "short string"
        ' already tested for exact equality
        string_similarity = 0
        Exit Function
    End If
    
    ' determine matching-window size
    mdist = Application.WorksheetFunction.Floor_Math(Sqr(L1))
    If verbose Then Debug.Print "match dist - " & mdist
    
    ' order-sensitive match index of each character such that
    '   (goose, pot) has only one match [2], [2] but
    '   (goose, oolong) has two matches [1,2], [2,3]
    'Set m1 = New ArrayList  ' not explicitly used, only for testing
    Set m2 = New ArrayList
    For i = 1 To L1
        window_start = Application.WorksheetFunction.Max(1, i - mdist)
        window_end = Application.WorksheetFunction.Min(L2, i + mdist)
        If window_start > L2 Then
            Exit For
        End If
        ' indices of letters to check, only if they haven't already been matched
        Set checkSet = New ArrayList
        For j = window_start To window_end
            If Not m2.Contains(j) Then
                checkSet.Add j
            End If
        Next j
        For Each k In checkSet
            If Mid(s1, i, 1) = Mid(s2, k, 1) Then
                'm1.Add i ' not used, only for testing
                m2.Add k
                Exit For
            End If
        Next k
    Next i
    
    ' final similarity formula
    matches = m2.Count
    If verbose Then Debug.Print "matches - " & matches
    
    If matches = 0 Then
        string_similarity = 0
    ElseIf matches = 1 Then
        string_similarity = Round((1 / L1 + 1 / L2 + 1) / 3, 3)
    Else
        ' check for out-of-order matches
        transposes = 0
        For n = 2 To matches - 1
            If m2.Item(n - 1) >= m2.Item(n) Then
                transposes = transposes + 1
            End If
        Next n
        If verbose Then Debug.Print "transposes - " & transposes
        string_similarity = Round((matches / L1 + matches / L2 + (matches - transposes) / matches) / 3, 3)
    End If
    
End Function

Sub test()
    Dim s1, s2 As String
    s1 = "Unit 1313 123 Westcourt Pl. N2L1B3"
    s2 = "1313-123 Westcourt Place N2L 1B3"
    's1 = "martha"
    's2 = "marhta2"
    s1 = "mean"
    s2 = "mane"
    
    MsgBox string_similarity(s1, s2, True)
End Sub
