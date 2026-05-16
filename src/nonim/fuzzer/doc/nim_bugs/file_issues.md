# Filing Bug Reports to nim-lang/Nim

For each bug folder, file a GitHub issue with:

**Title:** First line of the folder's `readme.md` (without the `# ` prefix)

**Body:** The content of `readme.md` with the following changes:
- Remove the first title line (the issue title already contains it)
- In the Reproduction section, replace "See the files in this directory:" with the repo link and file list:
  ```
  Full reproduction case with minimal renderer test, invalid/expected output, and a fuzzer:
  https://codeberg.org/heysokam/codegen.nim/src/branch/master/doc/nim_bugs/<folder_name>
  ```
  followed by the file list
- Hypothesis must be the last section

**Command:**
```
gh issue create --repo nim-lang/Nim --title "<title>" --body-file <temp_file>
```

After filing, update `tracker.md` with the returned issue URL in the Issue column.
