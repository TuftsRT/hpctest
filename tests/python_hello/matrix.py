#!/usr/bin/env python

# Simple matrix multiplication program

x = [[3,1,4],[1,5,9],[2,6,5]]

y = [[3,5,8,9],[7,9,3,2],[3,8,4,6]]

result = [[sum(a*b for a,b in zip(x_row,y_col)) for y_col in zip(*y)] for x_row in x]

for r in result:
    print(r)
