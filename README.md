# Funes Notes

Everyone says, “on Urbit, you own your own data”.  But until now, everyone has been limited to the same kind of web-based front-end.  And as cool as Urbit apps are, they’re pretty limited in terms of getting data into and out of your ship.

We are hopeful that this app will be useful to everyone, and the first step in creating new ways of interacting with your ship and your data.

## Installation - iOS

### Easy Mode

[Install from the App Store](https://apps.apple.com/us/app/funes-notes/id1627315560)

### Hard Mode

The code repo is here.  Build in Xcode and run on your device.

[https://github.com/funes-app/FunesNotes](https://github.com/funes-app/FunesNotes)


## Installation - MacOS

### Easy Mode

[Install homebrew](https://brew.sh/) and run this:

```
brew install funes-app/funes/funes-notes
```

### Hard Mode

As with iOS, you can build in Xcode and run on your device.  

(Since the app writes your ship's `+code` to your keychain, you will probably 
need a developer account to run it.)

[https://github.com/funes-app/FunesNotes](https://github.com/funes-app/FunesNotes)


## What you’ll need

### iPhone/iPad

Android people: sorry. Check back next year. 

## Or: MacOS

Windows/Linux people: don't hold your breath

### An Urbit ship

This can be any ship: planet, moon, comet, a galaxy. The current version doesn't require being on the Urbit network, so you could use even use a fakezod if you want to.

### A URL

Your Urbit ship has to be accessible to the outside world. You can use an IP address, or [setup a domain to point to your ship](https://urbit.org/using/running/hosting#getting-your-own-domain)

Unfortunately this probably excludes people running their ship on Port.  We’re trying to figure out a workaround on that.  Stay tuned.

In the meantime, you can use this as an excuse to move your ship to a server.  [Instructions for setting up a server here](https://urbit.org/using/running/hosting).
  
### An HTTPS connection

Apple won't let an app open a connection without HTTPS, so you need to set that up for your ship. [Go here for instructions](https://urbit.org/using/os/basics#configuring-ssl).

## Getting Help

There’s a group for Funes Notes, to get help and discuss.  Go here to join:

[~ribben-donnyl/funes](web+urbitgraph://group/~ribben-donnyl/funes)

You can also just DM ~ribben-donnyl, who will get right back to you.

