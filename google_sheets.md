# Google Sheets


## Formulas

Concatenate strings, numbers, etc.:

```
= "I have " & A2 & " dogs"
  Result when A2 = 8: "I have 8 dogs"
```

Zero-pad a number:

```
= RIGHT("0" & some_number, 2)
  Result when A2 = 9: "09"
  Result when A2 = 23: "23"
```

Format a minutes integer as `h:mm`:

```
= IF(L2>0, FLOOR(L2/60) & ":" & RIGHT("0"&MOD(L2,60), 2), "")
  Result when L2 = 601: "10:01"
```

KM to MI:

```
=IF(N2>0,ROUND(N2*0.6213712,1),"")
```

Look up a value from a table on another sheet:
(see also https://www.ablebits.com/office-addins-blog/2017/07/05/vlookup-google-sheets-example/#index-match-formula)

```
# The `false` flag is super important! `true` will lead to "taking the nearest value"
# instead of looking for an exact match.
=VLOOKUP(A8,count_per_email!$A$2:count_per_email!$B$9999,2,false)

# A more complicated version of the above:
=INDEX(count_per_email!$B$2:count_per_email!$B$9999, MATCH(A11,count_per_email!$A$2:count_per_email!$A$9999,0), 0)
```
