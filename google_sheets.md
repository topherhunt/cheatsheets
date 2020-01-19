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
