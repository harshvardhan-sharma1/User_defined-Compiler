:main() num
{
  list a[ 20 ].
  num b .
  num c .

  b = 3.
  c = 5.
  a[ 0 ] = b + c.
  print(a[ 0 ]).    $should print out 8

  a[ 1 ] = 100.
  print(a[ 1 ]).    $should print out 100

  a[ 2 ] = 200.
  print(a[ 2 ]).    $should print out 200

  a[ 3 ] = a[ 0 ] * (a[ 1 ] + c).
  print(a[ 3 ]).    $should print out 840 since 840 = 8 * (100 +5)
  
  $ Daniel's advice -- no ret in main
  $ret 0.

}
