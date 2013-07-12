# #### Root Require
{spawn}         = require 'child_process'
fs              = require 'fs'
$               = require('jquery').create()

# #### Local Require
logPackage      = require './logPackage.coffee'
writeFile       = require './writeFile.coffee'
testforlicense  = require './testForLicense.coffee'

# container for output list
openSource      = []
# async state
npmParsed       = false
extraParsed     = false

# #### NPM
npmParseAndPush = (data) ->
  # get project npm dependencies
  {dependencies} = JSON.parse String data
  # parse recursively to get all project unique npm modules
  modules       = []
  findModules   = (npm, deep) ->
    for k, v of npm 
      k = [k] unless deep 
      modules.push k 
      findModules v.dependencies, true if v.dependencies
  findModules dependencies

  filteredOSS   = []
  filteredOSS.push module for module in modules when filteredOSS.indexOf(module) is -1  

  pushedIndex     = 0
  jQueryScrape    = (module, deep) ->
    
    # get the npm modules package page from [npmjs.org](https://npmjs.org/)
    $.get "https://npmjs.org/package/#{module}", (data) ->
      # setup state of search
      license = null
      npmPage = $ data

      # `firster` insure that no duplicates will occur
      firster = true
      pushAndInc = (module, license) ->
        # return early if needed
        return unless firster
        firster = false

        # log the found module to the console
        logPackage module, license, "#{pushedIndex+1} of #{filteredOSS.length} npm #{if deep then '' else'\t| TOP LEVEL' }"
        
        # create array entry
        temp    = [module, license, 'NPM Package']
        # add `'Top Level'` to array if this module is declared and not a part of the npm nest
        temp.push 'Top Level' unless deep 
        # add module to output array
        openSource.push temp
        # increment value of currently pushed modules
        pushedIndex++
        # if we are at the last npm module write the file
        if pushedIndex is filteredOSS.length
          # stateness
          npmParsed = true
          # `writeFile` if vendors are parsed as well
          writeFile(openSource) if extraParsed

      # if we really can't fine the module's license just write out the url and add to output
      lastCall = (module, num) ->
        unless license
          pushAndInc module, "https://npmjs.org/package/#{module}"
          license = true

      # First check the metadata on the npm page for the presence of license information
      unless license
        # woo [`jQuery`](http://jquery.com/)
        npmPage.find('table.metadata th').each ->
          that = $ @          
          # if the NPM author was thoughtful enough to include the license in the metadata
          # simply use that
          if that.text() is 'License'
            license = that.siblings('td').eq(0).find('a').text()
            pushAndInc module, license if license

      # Second check the readme section fo the npm page for license information
      unless license
        # get the readme dom
        readme = npmPage.find('#readme').html() 
        if readme
          # parse and push if its found
          license = testforlicense readme
          pushAndInc module, license if license

      # async repo state
      repoFound = false 
      # Third actually check github repo for license information since the NPM author didn't bother to include the license information in npm
      unless license          
        npmPage.find('table.metadata th').each ->            
          that = $ @     
          # find the repo in the metadata   
          if that.text().indexOf('Repository') is 0
            # get the url of the repo
            github = that.find('a').attr('href')              
            if github                
              # test that the repo is from github
              if github.indexOf('github') is -1
                console.log 'NOT GIT '+ github
                # if the repo is not from github then fail
                lastCall module                                  
              else                                  
                # yay! we found a github repo!
                repoFound         = true                                         
                github            = github.split '//'
                
                # these are the most common places license information is found on github
                gitEndPoints      = ['LICENSE','LICENCE','README.mdown','README.md']     
                # async state to track get fails             
                failIndex         = 0
                # `checkGit` calls the repo path
                checkGit          = (endPoint, failCallback) ->
                  # generate path to raw file on github
                  filePath        = "https://raw.#{github[1]}/master/#{endPoint}"
                  # get!
                  $.get(filePath, (data) ->
                    # test for license without line breaks
                    license = testforlicense data.replace /(\r\n|\n|\r)/gm, ''
                    # if its license is found push it to the output
                    if license
                      pushAndInc module, license 
                    # otherwise track this fail
                    else failCallback()
                  # if the get failed track the fail
                  ).fail -> failCallback()

                # loop executes `checkGit`s
                for endPoint in gitEndPoints
                  checkGit endPoint, ->
                    # if the get failed to work or find the license increment
                    failIndex++
                    # if all gets have failed to find anything fail the whole lookup
                    if failIndex is gitEndPoints.length 
                      lastCall module, 1 

            # if repo was not found in the metadata we now have no hope of finding the license
            else lastCall module, 2
      
      # if license is not found, and the repo is not found on the npm page
      # we are out of luck, fail
      lastCall module, 3 unless repoFound
          
  # push unique npm modules to list 
  for module in filteredOSS
    if typeof module is 'string'   
      jQueryScrape module.toLowerCase(), true
    else
      jQueryScrape module[0].toLowerCase(), false

# #### Connect Assets Front End
vendorParseAndPush = (err, data, callback) ->
  # parse lines that contain vendor stuff
  parsetarget = data.split('#').filter (line) ->
    return false unless line.substr(0, 2) is ' ['
    return true
  # parse vendor name from line
  parsetarget[i] = parsetarget[i].split(']') for i in [0...parsetarget.length]
  vendors        = parsetarget.map (item) -> item[0].replace(' [','')
  licenses       = parsetarget.map (item) -> item[1].split('|')[1].trim().replace('\n','')
  pairs          = for i in [0...vendors.length]
    [vendors[i].toLowerCase(), licenses[i], 'Front End Project']
  # push unique vendor files to list
  filteredOSS = []
  filteredOSS.push pair for pair in pairs when filteredOSS.indexOf(pair) is -1
  for module, i in filteredOSS
    logPackage module[0], module[1], "#{i+1} of #{filteredOSS.length} frontend"
    openSource.push module 

  callback()

# #### Parse `osslist.json`
extraParseAndPush = (err, data) ->
  # handle absense of `osslist.json` file
  unless data
    extraParsed = true
    writeFile(openSource) if npmParsed
    return console.log 'OPTIONAL `osslist.json` NOT FOUND' 
  # get config information along with declared OSS
  {OSS, ConnectAsset} = JSON.parse String data

  # state!
  i       = 0
  total   = 0
  total++ for k, v of OSS 

  # loop over delcared OSS
  for project, vals of OSS
    # log them out to the console 
    logPackage project.toLowerCase(), vals.license, "#{i+1} of #{total} OSS"
    # add them to the output
    openSource.push [project.toLowerCase(), vals.license, 'OSS']
    i++

  # if we are parsing for `Connect Assets` then do so...
  if ConnectAsset
    j     = 0
    for asset in ConnectAsset
      fs.readFile asset, 'utf8', (err, data) -> 
        throw new Error "ConnectAsset #{asset} NOT FOUND" unless data
        vendorParseAndPush err, data, ->
          j++
          if j is ConnectAsset.length 
            extraParsed = true
            writeFile(openSource) if npmParsed
  else
    # write the file if npmParse is also finished
    extraParsed = true
    writeFile(openSource) if npmParsed

# ### MAIN 
# spawn `npm list --json=true` process
list = spawn 'npm', ['list', '--json=true']
# `npm list` callback
list.stdout.on 'data', npmParseAndPush
# read `osslist.json` 
fs.readFile 'osslist.json', 'utf8', extraParseAndPush