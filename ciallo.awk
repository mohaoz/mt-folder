# build.awk
BEGIN {
  state = "IGNORE"
}

{
  line = $0
  stripped = line
  sub(/^[ \t]*/, "", stripped)
  indent = length(line) - length(stripped)
}

# -------- state switch --------
stripped == "// CIALLO_MD" {
  if (state == "CPP")
    print "```"
  state = "MD"
  next
}

stripped == "// CIALLO_CODE" {
  state = "CPP"
  base_indent = indent
  print "```cpp"
  next
}

stripped == "// CIALLO_END" {
  if (state == "CPP")
    print "```"
  state = "IGNORE"
  next
}

# -------- content --------
state == "MD" {
  md = stripped
  sub(/^\/\/ ?/, "", md)
  print md
  next
}

state == "CPP" {
  # streaming dedent based on directive indent
  if (indent >= base_indent)
    print substr(line, base_indent + 1)
  else
    print stripped   # defensive fallback
  next
}

# -------- IGNORE --------
{
  # do nothing
}
