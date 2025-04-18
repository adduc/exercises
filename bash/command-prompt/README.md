# Customizing the Bash Prompt through PROMPT_COMMAND

The `PS1` variable in bash is used to define the primary prompt string, which is displayed when the shell is ready to accept a command. However, you can also customize the prompt dynamically using the `PROMPT_COMMAND` variable. This exercise demonstrates one way to do that.

## Usage

```sh
# Because prompt.sh expects to interact with environment variables in
# the current shell session, it should be sourced instead of executing
# it.
source prompt.sh
```

## Example

```sh
# Set the PROMPT_COMMAND to a function that updates the PS1 variable
PROMPT_COMMAND='PS1="\u@\h:\w\$ "'

# Now, when you type a command, the prompt will show your username,
# hostname, and current working directory.
```
