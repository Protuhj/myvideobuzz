### After years of development, I have stopped supporting the Roku platform. I will be setting this repository to archived, as I do not plan on reviving it.
### Feel free to fork!

MyVideoBuzz -- Protuhj's Fork (Archived)
=============

This project is a fork of [Roku YouTube](https://github.com/jesstech/Roku-YouTube) by [jesstech](https://github.com/jesstech). Updates include API fixes, additional features, and the removal of OAuth settings.

> **Note:** as of 7 May 2015, versions up to and including 1.7.4 will not work well, if at all, with YouTube.

Installation
============

You must first enable development mode on the Roku. From Roku's top-level menu (launch screen), enter the following sequence on your remote control:

> **Note**: This sequence _cannot_ be entered from a mobile app (iOS, Android, etc.). A physical Roku remote is required!

    Home 3x, Up 2x, Right, Left, Right, Left, Right

On newer versions of the Roku firmware, you will then be prompted to set a web server password. Choose a password (and remember it), then reboot the Roku.

When development mode is enabled on your Roku, you can install dev packages
from the Application Installer which runs on your device at the device's IP
address. Open any standard web browser and visit the following URL:

    http://<your.roku.ip.address>  # for example, http://192.168.1.7, or whatever address belongs to your Roku

[**Download the source zip file**](https://github.com/Protuhj/myvideobuzz/releases/download/v2.3.0/MyVideoBuzz_v2_3_0.zip) and upload it to your Roku device.

> **Caution**: _Do not_ unzip this file! Additionally, you must upload the entire file to your Roku.

Due to limitations in the sandboxing of development Roku channels, you can have only one development channel installed at a time.

### Alternative Installation Method: Windows users

Download the whole repository &rarr; [**Current Release: 2.3.0**](https://github.com/Protuhj/myvideobuzz/archive/v2.3.0.zip). Then, unzip the archive, edit the included `\deploy\rokus.txt` file, and add your Roku device(s) network and authentication information to it, as illustrated in the example below:

    # <roku.ip.address><white space>rokudev:<rokuPassword>
    192.168.1.56 rokudev:rokupassword

This will upload the `myvideobuzz.zip` file to the Roku(s) you provide in the `rokus.txt` file.

You can copy the `.\deploy\` folder somewhere on your hard drive, and modify the `deploy.bat` file to change the location of the zip file. Do so by changing the `ZIP_LOCATION` variable to point to the location of the zip you would like to deploy.

By doing this, you won't have to edit the `rokus.txt` file in the future when updating your Roku(s).

### Updating the Channel

As of version 1.7.2, VideoBuzz supports auto-updating. This means that once installed, you can update VideoBuzz from within the channel itself.

This can happen in one of three ways:

1. A new release is deployed.
2. The current master (development) build has a newer version (major, minor, build number) than the currently installed version.
3. A channel force update (to the current latest release) is made.
    + The only requirement needed to use this feature is that you enter your Roku password. Recall that you set a password while enabling development mode. (The username will always remain "rokudev".)
    + This can be accomplished by navigating to _Settings_ from the channel's main page, accessing the item entitled _General_, choosing _Roku Development Password_, and finally entering your Roku's password.
    + Once you've entered your password, go back to the main _Settings_ page, and go to _About_ -- you can then use the buttons at the bottom of the screen to choose which update option you'd like.

> **Note**: if a channel update is successful, there is no notification as such, it will just restart itself, similar to when you normally re-upload the channel's zip file.

### Usage

This channel uses publicly available information from your YouTube account. To permit full channel functionality, you will need to ensure that your account Subscriptions, Playlists, and Favorites are publicly accessible.

* To do this, go to https://www.youtube.com/account_privacy and make sure the checkboxes under _Likes and Subscriptions_ are unchecked.
* Then, go to https://www.youtube.com/view_all_playlists to manage which playlists you would like visible in VideoBuzz.
    + Click on the "Edit" button next to each playlist you want to change.
    + Then on the next page, click "Playlist settings" and change _PLAYLIST PRIVACY_ to `Public`.

### Debugging

Your Roku's debug console can be accessed by Telnet at port `8085`:

    telnet <your.roku.ip.address> 8085

## Contributing

Want to contribute? Great! Visit the [VideoBuzz subreddit](http://www.reddit.com/r/videobuzz).
You can also check out my [Facebook page](https://www.facebook.com/Protuhj).
