function __auto_script_shorten --description "shortens the file path" --argument file
    echo $file \
    | sed -e "s|^$GHQ_ROOT\/github\.com|gh|" \
    | sed -e "s|^$GHQ_ROOT\/bitbucket\.org|bb|" \
    | sed -e "s|^$HOME|~|"
end

function __auto_script_confirm --description "Asks the user for confirmation" --argument prompt
    if test -z "$prompt"
        set prompt "Continue?"
    end

    while true
        read -n 1 -l -p 'set_color red; echo -n "$prompt [y/n]: "; set_color normal' confirm

        switch $confirm
            case Y y
                return 0
            case '' N n
                return 1
        end
    end
end

function __auto_script_file_line --description "Builds an entry for the auto_script whitelist" --argument file
    echo (md5 -q $file)\t"$file"
end

function __auto_script_allowed --description "Checks if the file is whitelisted" --argument file
    set -l script_list $HOME/.config/fish/auto_script_allowed

    # Initialize file if needed
    if test ! -e "$script_list"
        touch $script_list
    end

    # Look for occurences in the whitelist
    grep -q (__auto_script_file_line $file) $script_list

    return $status
end

function __auto_script_prompt --description "Asks for confirmation when the file is not whitelisted" --argument file
    # File does not exist
    if test ! -e "$file"
        return 1
    end

    # If the file is not whitelisted, ask for confirmation
    if not __auto_script_allowed $file
        if __auto_script_confirm "new script "(__auto_script_shorten $file)", allow it?"
            echo (__auto_script_file_line $file) >> $HOME/.config/fish/auto_script_allowed
        else
            return 1
        end
    end
    return 0
end

function __auto_script_run --argument script
    if test -e "$script"
        if __auto_script_prompt $script
            echo running $script
            #__auto_script_prompt $script#; and fish $script
        end
    end
end

function __auto_script_handle_dir --on-variable auto_script_dir
    if test ! -z "$auto_script_dir"
        __auto_script_run $dirprev[(count $dirprev)]/.unload.fish
        __auto_script_run (pwd)/.load.fish
    end
end

function __auto_script_handle_dirprev --on-variable dirprev
    if status --is-interactive
        set --local previous_dir $dirprev[(count $dirprev)]
        if test ! "$auto_script_dir" = "$previous_dir"
            set -g auto_script_dir $previous_dir
        end
    end
end

function __auto_script
    __auto_script_handle_dirprev
    __auto_script_handle_dir
end
