#!/bin/bash

# Get Old Details
echo '\nYou will enter the old server information, make sure it is accessible!'
read -p "Old Server IP: " old_ip
read -p "Old Server User: " old_user
read -p "Old Server Password: " old_pw

# Show Old Details
echo "OLD IP: ${old_ip} - OLD User: ${old_user} - OLD Pw: ${old_pw}"

# Old Approval
read -p "Is the informations correct? (y / n): " approval

# Old Approval Condition
if [ "$approval" = "e" ]; then
    echo 'APPROVED.\n'
    # Stage 1
    mysql -h $old_ip -u $old_user -p"${old_pw}" --skip-column-names -A -e"SELECT CONCAT('SHOW GRANTS FOR ''',user,'''@''',host,''';') FROM mysql.user WHERE user<>'' and user NOT IN ('mysql.session','mysql.sys','debian-sys-maint','root');" | mysql -h $old_ip -u $old_user -p"${old_pw}" --skip-column-names -A | sed 's/$/;/g' > user_grants.sql

    # Stage 2
    echo 'Check the version information for the old server.\n'
    read -p "MySQL Version 5.6 and Before 5.6? (y / n): " mysql_version

    if [ "$mysql_version" = "e" ]; then
        read -p "MySQL Version set to 5.6 and earlier. Do you confirm? (y / n): " version_approval

        if [ "$version_approval" = "e" ]; then
            mysql -h $old_ip -u $old_user -p"${old_pw}" --skip-column-names -A mysql -e "SELECT CONCAT('CREATE USER \'', user, '\'@\'', host, '\' IDENTIFIED WITH \'mysql_native_password\' AS \'', password,'\';') FROM mysql.user WHERE user NOT IN ('mysql.session','mysql.sys','debian-sys-maint','root');" > create_user.sql
        else
            echo 'You did not approve. Start again.'
            exit 2
        fi

    else
        read -p "MySQL Version set to 5.6. Do you confirm? (y / n): " version_approval

        if [ "$version_approval" = "e" ]; then
            mysql -h $old_ip -u $old_user -p"${old_pw}" --skip-column-names -A mysql -e "SELECT CONCAT('CREATE USER \'', user, '\'@\'', host, '\' IDENTIFIED WITH \'mysql_native_password\' AS \'', authentication_string,'\';') FROM mysql.user WHERE user NOT IN ('mysql.session','mysql.sys','debian-sys-maint','root');" > create_user.sql
        else
            echo 'You did not approve. Start again.'
            exit 2
        fi
    fi
    
    # Get New Details
    echo '\nYou will enter new server information, make sure it is accessible!'
    read -p "New Server IP: " new_ip
    read -p "New Server User: " new_user
    read -p "New Server Password: " new_pw

    # Show New Details
    echo "NEW IP: ${new_ip} - NEW User: ${new_user} - NEW Pw: ${new_pw}"

    # New Approval
    read -p "Is the informations correct? (y / n): " new_approval

    # New Approval Condition
    if [ "$new_approval" = "e" ]; then
        echo 'APPROVED.\n'

        # Last Approval
        read -p "If everything is ok, I will transfer users to your new server? (y / n): " last_approval

        # Last Approval Condition
        if [ "$last_approval" = "e" ]; then
            echo 'APPROVED.\n'

            # Stage 3
            mysql -h $new_ip -u $new_user -p"${$new_pw}" < create_user.sql

            # Stage 4
            mysql -h $new_ip -u $new_user -p"${$new_pw}" < user_grants.sql

            # Success after delete old files.
            rm -rf create_user.sql
            rm -rf user_grants.sql

            echo 'All process are completed.'
            exit 0
        else
            echo 'You did not approve. Start again.'
            exit 2
        fi

    else
        echo 'You did not approve. Start again.'
        exit 2
    fi
else
    echo 'You did not approve. Start again.'
    exit 2
fi
