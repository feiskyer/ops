* precede each line by line number

```bash
awk '{print NR, $0}' filename
```

* replace first field by line number

```bash
awk '{$1=NR; print}' filename
```

* print field 1 and field 2

```bash
awk '{print $1,$2}' fielname
```

* print last field 

```bash
awk '{print $NF}' filename
```

* print non empty lines

```bash
awk 'NF>0{print $0}' filename
 ```
 
* print if more than 4 fields
 
```bash
awk 'NF>4{print $0}' filename
 ```
 
* print matching lines (egrep)
 
 ```bash
awk '/test.*/{print $0}'  filename
 ```
 
* print lines where first field matches

```bash
awk '$1 ~ /^print.*/{print $0}' filename
```

* calcuting sum of field 2

```bash
awk 'BEGIN{sum=0}{sum+=$2}END{print sum}' filename
```

* for loop

```bash
awk '{sum=0; for(i=1;i<=NF;i++)sum+=$i; print sum}' filename
```

* make arrays

```bash
awk '{n = split($0, array); print array[1], array[3]} ' filename 
```

* reverse a file

```bash
awk '{x[NR]=$0} END{for(i=NR;i>0;i--)print x[i]}' filename 
```

* Associative Arrays 

```bash
awk '{amount[$1]=$2} END{for(name in amount) print name, amount[name]}' filename
```



