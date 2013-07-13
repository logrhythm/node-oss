# Node OSS

This is a simple npm module for documenting the OSS in your node.js project. See our [documentaion here.](http://logrhythm.github.io/node-oss)

## How it works

**node-oss** piggy packs off of a native npm function [`npm list`](https://npmjs.org/doc/list.html). This function recursively returns all the npm modules in your project. **node-oss** uses this list and finds all the unique projects as npm's nested nature produces many duplicates. It then scrapes the web to find the license for each npm module. Finally it returns a `.CSV` listing all the modules alphabetically along with their licenses.

#### What if **node-oss** fails to find the license?

If it fails to scrape the license, **node-oss** will place the url for the npm package in its place so you can do what you need to do to find it yourself.

#### How about non-npm open source?

Assuming you wish to document all the OSS used in your node.js project, you may inform **node-oss** of root OSS project (like node.js itself) by add a file called `osslist.json` to your root directory. In `osslist.json` you can enumerate further OSS projects (see below).

There is also a feature to parse front end projects, documentation coming soon.

## Usage

To use **node-oss** simple run the following command:

     sudo npm install -g node-oss
     
(Note this package does **not work in windows!** and likely never will.) After you have it installed simple `cd` to your root directory and run

     node-oss
     
and watch the data come back in your terminal. When its done it will write a `.CSV` file to the directory called `openSource-[date].csv`.

If you wish you may declare further OSS to be included in the `.CSV`, by adding `osslist.json` to the root directory. Here is an example of how this file is to be formatted:

     {
          "OSS" : {
               "Nodejs" : {
                    "url"     : "https://github.com/joyent/node",
                    "license" : "https://raw.github.com/joyent/node/master/LICENSE"
               },
               "Another Project" : {
                    "license" : "MIT"
               },
               "Yet Another" : {
                    "url"     : "path/for/your/refference",
                    "license" : "BSD"
               }
          }
     }
     
including the `url` is entirely optional right now, but may have a use in the future. For the moment its just for your reffernce as a part of documentaion.
