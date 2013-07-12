# ### Write the File
# this writes out the final `.CSV` output

# #### Root Require
fs          = require 'fs'

writeFile = (openSource) ->
  # sort the array alphabetically by package name
  openSource.sort (a,b) -> 
    return -1 if a[0] < b[0]
    return 1  if a[0] > b[0]
    return 0
  
  # create date string for file name
  now = new Date()
  dateString  = "#{now.getMonth()+1}-#{now.getDate()}-#{now.getFullYear()}.#{now.getHours()}-#{now.getMinutes()}"
  
  # generate string for contents of file 
  fileString  = 'Project,License,Type,Npm Depth\n'
  fileString += "#{oss[0]},#{oss[1]},#{oss[2]},#{oss[3] or ''}\n" for oss in openSource
  fileString  = fileString.substr(0, fileString.length-1)

  # filename
  fileName    = "openSource-#{dateString}.csv"

  # write out the actual file
  fs.writeFile fileName, fileString, (err) ->
    # after file is written either 
    # - alert the user that the file is ready
    # - inform the user of an error
    if err then console.log err else console.log "Unique open source dependencies saved to `#{fileName}`"

module.exports = writeFile