#!/bin/bash

# Get Old Details
echo '\nEski sunucu bilgilerini gireceksin, erişime açık olduğundan emin ol!'
read -p "Eski Sunucu IP: " old_ip
read -p "Eski Sunucu User: " old_user
read -p "Eski Sunucu Password: " old_pw

# Show Old Details
echo "Eski IP: ${old_ip} - Eski Kullanıcı: ${old_user} - Eski Parola: ${old_pw}"

# Old Approval
read -p "Bilgiler Dogru Mu? (e / h): " approval

# Old Approval Condition
if [ "$approval" = "e" ]; then
    echo 'ONAY ALINDI.\n'
    # Stage 1
    mysql -h $old_ip -u $old_user -p"${old_pw}" --skip-column-names -A -e"SELECT CONCAT('SHOW GRANTS FOR ''',user,'''@''',host,''';') FROM mysql.user WHERE user<>'' and user NOT IN ('mysql.session','mysql.sys','debian-sys-maint','root');" | mysql -h $old_ip -u $old_user -p"${old_pw}" --skip-column-names -A | sed 's/$/;/g' > user_grants.sql

    # Stage 2
    echo 'Eski sunucu için sürüm bilgilerini işaretleyin.\n'
    read -p "MySQL Sürümü 5.6'dan Önce mi? (e / h): " mysql_version

    if [ "$mysql_version" = "e" ]; then
        read -p "MySQL Sürümü 5.6 ve öncesi olarak ayarlandı. Onaylıyor musunuz? (e / h): " version_approval

        if [ "$version_approval" = "e" ]; then
            mysql -h $old_ip -u $old_user -p"${old_pw}" --skip-column-names -A mysql -e "SELECT CONCAT('CREATE USER \'', user, '\'@\'', host, '\' IDENTIFIED WITH \'mysql_native_password\' AS \'', password,'\';') FROM mysql.user WHERE user NOT IN ('mysql.session','mysql.sys','debian-sys-maint','root');" > create_user.sql
        else
            echo 'Onay vermediniz. Tekrar başlayın.'
            exit 2
        fi

    else
        read -p "MySQL Sürümü 5.6 sonrası olarak ayarlandı. Onaylıyor musunuz? (e / h): " version_approval

        if [ "$version_approval" = "e" ]; then
            mysql -h $old_ip -u $old_user -p"${old_pw}" --skip-column-names -A mysql -e "SELECT CONCAT('CREATE USER \'', user, '\'@\'', host, '\' IDENTIFIED WITH \'mysql_native_password\' AS \'', authentication_string,'\';') FROM mysql.user WHERE user NOT IN ('mysql.session','mysql.sys','debian-sys-maint','root');" > create_user.sql
        else
            echo 'Onay vermediniz. Tekrar başlayın.'
            exit 2
        fi
    fi
    
    # Get New Details
    echo '\nYeni sunucu bilgilerini gireceksin, erişime açık olduğundan emin ol!'
    read -p "Yeni Sunucu IP: " new_ip
    read -p "Yeni Sunucu User: " new_user
    read -p "Yeni Sunucu Password: " new_pw

    # Show New Details
    echo "Yeni IP: ${new_ip} - Yeni Kullanıcı: ${new_user} - Yeni Parola: ${new_pw}"

    # New Approval
    read -p "Bilgiler Dogru Mu? (e / h): " new_approval

    # New Approval Condition
    if [ "$new_approval" = "e" ]; then
        echo 'ONAY ALINDI.\n'

        # Last Approval
        read -p "Herşey tamamsa yeni sunucuna kullanıcıları aktaracağım? (e / h): " last_approval

        # Last Approval Condition
        if [ "$last_approval" = "e" ]; then
            echo 'ONAY ALINDI.\n'

            # Stage 3
            mysql -h $new_ip -u $new_user -p"${$new_pw}" < create_user.sql

            # Stage 4
            mysql -h $new_ip -u $new_user -p"${$new_pw}" < user_grants.sql

            # Success after delete old files.
            rm -rf create_user.sql
            rm -rf user_grants.sql

            echo 'İşlemler tamamlandı.'
            exit 0
        else
            echo 'Onay vermediniz. Tekrar başlayın.'
            exit 2
        fi

    else
        echo 'Onay vermediniz. Tekrar başlayın.'
        exit 2
    fi
else
    echo 'Onay vermediniz. Tekrar başlayın.'
    exit 2
fi
