# ### Test for License
# this accepts a sting and attempts to parse out the license

testforlicense = (str) ->

  # look for the presence of the MIT license
  isMIT     = if str.indexOf(' MIT ')  is -1 then false else true
  # many users of the MIT license omit "MIT" from the license file
  # so test for a portion of the license text itself
  unless isMIT 
    isMIT   = if str.indexOf('a copy of this software and associated documentation files (the') is -1 then false else true
  
  # look for presence of BSD license
  isBSD     = if str.indexOf('BSD')    is -1 then false else true

  # look for presence of Apache 2.0 license
  isApache  = if str.indexOf('Apache') is -1 then false else true
  isTwo     = if str.indexOf('2.0')    is -1 then false else true

  # insure that only 1 of the above licenses was found
  # if multiples are found or none are found return `null`
  res = null
  res = 'MIT'        if isMIT    and not isBSD and not isApache
  res = 'BSD'        if isBSD    and not isMIT and not isApache
  res = 'Apache 2.0' if isApache and isTwo and not isMIT and not isBSD
  return res

module.exports = testforlicense