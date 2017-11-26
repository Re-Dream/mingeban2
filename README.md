# mingeban2

The administration tool used on the Re-Dream server, and the second attempt at making an admin mod by Tenrys.

# What's to come

Tasks that have been completed a while ago will get removed from this list.
This might turn into a feature list when the project gets completed. 

- [x] Rank system with levels and special root modes.
    - [x] Implement root functionality.
- [x] Easily implementable commands.
    - [x] Add property to check if rank level checking between two players should be handled by the RunCommand or a command's callback.
    - [x] Server console support.
    - [x] Load commands in mingeban/commands folder.
    - [x] Network to players so we can add GUI, clientside console support, ...
    - [ ] Autocompletion
        - [x] Console
        - [ ] Chat (not priority)
    - [x] Turn rank checking into some permission system that is not hardcoded?
    - [ ] Write a documentation / guide about their creation. (if needed)
    - [ ] More argument types (Rank, Weapon (and their classes))
    - [ ] More player selectors
- [x] Countdown system
- [x] Ban system

### Might come out as separate add-ons

- [ ] An in-game panel to work with commands, and other aspects of the whole add-on.
- [ ] Context menu player extra properties to interact with them.

### To Do When Done

- [ ] Add more argument types sanity checks everywhere in order to not fall apart if we make one little mistake.
- [ ] Add more comments to explain complicated stuff
