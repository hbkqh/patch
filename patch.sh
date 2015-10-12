

#!/bin/bash

DISK_NO="/dev/sda1"

cat config |cut -d "|" -f 1 |cut -d : -f 2 |sort |uniq |awk '{print "("FNR") "$0}' > patchmodule
count=$(cat config |cut -d "|" -f 1 |cut -d : -f 2 |sort |uniq |wc -l)

#date
DATE=`date +"%y-%m-%d %H:%M:%S"`

#ip
IPADDR=`ifconfig eth0|grep 'inet addr'|sed 's/^.*addr://g' |sed 's/Bcast:.*$//g'`

#hostname
HOSTNAME=`hostname -s`

#user
USER=`whoami`

#disk_check
DISK_SDA=`df -h | grep $DISK_NO | awk '{print $5}'`

#cpu_average_check
cpu_uptime=`cat /proc/loadavg | cut -c1-14`

select_module=0
declare flag=0
patch_num=0
restore_num=0
patch_suc=0
restore_suc=0
restoremodulecount=0
clear

#输入错误函数，无参数
echo_error(){
  echo "----------------------------------"
  echo "|          输入有误!!!           |"
  echo "|    请重新输入正确的数字!       |"
  echo "----------------------------------"
  sleep 2
  clear
}


#没有打点时的还原菜单输出
echo_nopatch(){
echo "========================================"
echo "     在本机还没有打点，请按0返回：      "
echo "========================================"
echo "(0) 返回"
cat << EOF
-----------------------------------------------
|**********请输入数字0返回上一层菜单**********|
-----------------------------------------------
EOF
 read -p "请输入数字0返回上一层菜单: " input2
 case $input2 in 
 0) 
 clear 
 break
 ;;
 *) 
 echo_error
 ;;
 esac
}


#菜单转打补丁中间函数,1个参数：1.打点的模块选择数字
to_patch(){

select_module=$(sed -n "$1p" patchmodule |cut -d " " -f 2)

cat config | grep "module:$select_module" > config.temp

current_location=$(pwd)
patch "config.temp" "${current_location}"

fail=`expr $patch_num - $patch_suc`
if [ $fail -eq 0 ]
then
echo -e "模块$select_module打点${patch_num}个文件，成功${patch_suc}个\n\n"
else
echo -e "模块$select_module打点${patch_num}个文件，成功${patch_suc}个，\033[31m失败${fail}个\033[0m\n\n"
fi

sleep 3
}




#菜单转还原的中间函数,1个参数：1.还原的模块选择数字
to_restore(){

select_restore_module=$(sed -n "$1p" restoremodule |cut -d " " -f 2)

cat restore | grep "module:$select_restore_module" > restore.temp

current_location=$(pwd)
restore "restore.temp" "${current_location}" "${select_restore_module}"

fail=`expr $restore_num - $restore_suc`
if [ $fail -eq 0 ]
then
echo -e "模块$select_restore_module还原${restore_num}个文件，成功${restore_suc}个\n\n"
else
echo -e "模块$select_restore_module还原${restore_num}个文件，\033[31m失败${fail}个\033[0m\n\n"
fi

sleep 3
}



#拷贝文件写日志,3个参数：1.文件原始位置；2.文件目的位置；3.拷贝的结果
write_log_copy(){
  source_log=$1
  destination_log=$2
  copy_result=$3
  if [ ! -e log.txt ]
    then
    touch log.txt
    echo "----------create log file success----------" > log.txt
    echo $(date "+%Y-%m-%d %H:%M:%S") >> log.txt 
    echo "this file is for recording" >> log.txt
  fi
  if [ $copy_result -eq 1 ]
    then
    echo $(date "+%Y-%m-%d %H:%M:%S")"：拷贝文件：${source_log} 到 ${destination_log}成功" >> log.txt
    elif [ $copy_result -eq 2 ]
    then
    echo $(date "+%Y-%m-%d %H:%M:%S")"：拷贝文件：${source_log} 到 ${destination_log}失败" >> log.txt

  fi

}


#备份文件写日志,2个参数：1.备份的文件；2.备份的结果
write_log_backup(){
  file_backup_log=$1
  backup_result=$2
  if [ ! -e log.txt ]
    then
    touch log.txt
    echo "----------create log file success----------" > log.txt
    echo $(date "+%Y-%m-%d %H:%M:%S") >> log.txt 
    echo "this file is for recording" >> log.txt
  fi
  if [ $backup_result -eq 1 ]
    then
    echo $(date "+%Y-%m-%d %H:%M:%S")"：尝试备份文件${file_backup_log}，无需备份" >> log.txt
    elif [ $backup_result -eq 2 ]
    then
    echo $(date "+%Y-%m-%d %H:%M:%S")"：尝试备份文件${file_backup_log}，备份成功，备份文件是${file_backup_log}.backup" >> log.txt
    elif [ $backup_result -eq 3 ]
    then
    echo $(date "+%Y-%m-%d %H:%M:%S")"：尝试备份文件${file_backup_log}，备份失败，${file_backup_log}.backup不存在" >> log.txt
    elif [ $backup_result -eq 4 ]
    then
    echo $(date "+%Y-%m-%d %H:%M:%S")"：尝试备份文件${file_backup_log}，备份失败，${file_backup_log}不存在" >> log.txt
	elif [ $backup_result -eq 5 ]
    then
    echo $(date "+%Y-%m-%d %H:%M:%S")"：打点配置文件：${file_backup_log} 不存在，出错" >> log.txt
  fi

}



#还原文件写日志,2个参数：1.还原的文件；2.还原的结果
write_log_restore(){
  file_restore_log=$1
  restore_result=$2
  if [ ! -e log.txt ]
    then
    touch log.txt
    echo "----------create log file success----------" > log.txt
    echo $(date "+%Y-%m-%d %H:%M:%S") >> log.txt 
    echo "this file is for recording" >> log.txt
  fi
  if [ $restore_result -eq 1 ]
    then
    echo $(date "+%Y-%m-%d %H:%M:%S")"：还原文件${file_restore_log}成功" >> log.txt
    elif [ $restore_result -eq 2 ]
    then
    echo $(date "+%Y-%m-%d %H:%M:%S")"：还原文件${file_restore_log}成功，但是备份文件${file_restore_log}.backup还存在" >> log.txt
    elif [ $restore_result -eq 3 ]
    then
    echo $(date "+%Y-%m-%d %H:%M:%S")"：尝试还原文件${file_restore_log}，无法还原，${file_restore_log}.backup不存在" >> log.txt
	elif [ $restore_result -eq 4 ]
    then
    echo $(date "+%Y-%m-%d %H:%M:%S")"：还原配置文件：${file_restore_log}不存在，出错" >> log.txt
	elif [ $restore_result -eq 5 ]
    then
    echo $(date "+%Y-%m-%d %H:%M:%S")"：还原文件：${file_restore_log}失败" >> log.txt
  fi
}




#备份函数，2个参数：1.文件名；2.文件位置
file_backup(){
file_backup="$2/$1"

if [ ! -e "${file_backup}" ]
then
 write_log_backup "${file_backup}" "4"
 echo -e "\033[31m需要备份的文件${file_backup}不存在 \033[0m"
 exit 1
fi

if [ -e "${file_backup}.backup" ]
then
 write_log_backup "${file_backup}" "1"
 echo "不需要备份${file_backup}.backup"
else
 cp -a "${file_backup}" "${file_backup}.backup"
 if [ ! -f "${file_backup}.backup" ]; then
    echo -e "\033[31m备份文件${file_backup}失败 \033[0m"
    write_log_backup "${file_backup}" "3"
    exit 1
 fi
 write_log_backup "${file_backup}" "2"
 echo "备份${file_backup}.backup成功"
 echo "module:${select_module}|file:${file_backup}.backup|" >> restore
 
fi

}


#文件移动函数，3个参数：1.文件名；2.文件拷贝的原始位置；3.文件目标位置
copy_backup_file(){
file_name=$1
source_path=$2
destination_path=$3

#备份
file_backup "${file_name}" "${destination_path}"

#拷贝
cp -a "${source_path}/${file_name}" "${destination_path}"
if [ ! -f "${destination_path}/${file_name}" ]; then
    echo -e "\033[31m拷贝文件：${source_path}/${file_name} 到 ${destination_path}失败\n\033[0m"
    write_log_copy "${source_path}/${file_name}" "${destination_path}" "2"
    exit 1
fi

#权限属性操作
user_mode=$(ls -l "${destination_path_}/${file_name_}.backup" | cut -b 2-4)
chmod "u=${user_mode}" "${destination_path}/${file_name}"
group_mode=$(ls -l "${destination_path_}/${file_name_}.backup" | cut -b 5-7)
chmod "g=${group_mode}" "${destination_path}/${file_name}"
other_mode=$(ls -l "${destination_path_}/${file_name_}.backup" | cut -b 8-10)
chmod "o=${other_mode}" "${destination_path}/${file_name}"

#用户属性操作
gourp_mode=$(ls -l "${destination_path_}/${file_name_}.backup" | cut -d " " -f 4)
chgrp "${gourp_mode}" "${destination_path_}/${file_name_}"
user_mode=$(ls -l "${destination_path_}/${file_name_}.backup" | cut -d " " -f 3)
chown "${user_mode}" "${destination_path_}/${file_name_}"

patch_suc=`expr $patch_suc + 1`
write_log_copy "${source_path}/${file_name}" "${destination_path}" "1"
echo -e "拷贝文件：${source_path}/${file_name} 到 ${destination_path}成功\n"
}



#打补丁主函数,2个参数：1.打点配置临时文件名；2.配置文件的位置
patch(){
config_temp="$2/$1"
if [ ! -e "${config_temp}" ]
then
 write_log_backup "${config_temp}" "5"
 echo -e "\033[31m打点配置文件出错 \033[0m"
 exit 1
fi

patch_num=0
patch_suc=0
while read line
do
    patch_num=`expr $patch_num + 1`
    file_name_=$(echo $line |cut -d "|" -f 2 |cut -d : -f 2)
    source_path_="$2$(echo $line |cut -d "|" -f 3 |cut -d : -f 2)"
#   source_path_=$2
    destination_path_="$2$(echo $line |cut -d "|" -f 4 |cut -d : -f 2)"
    echo "文件名：${file_name_}"
    echo "原路径：${source_path_}"
    echo "目的路径：${destination_path_}"
    copy_backup_file "${file_name_}" "${source_path_}" "${destination_path_}"
done < $config_temp

}


#还原主函数,3个参数：1.还原配置文件名；2.配置文件的位置；3.选择的模块
restore(){
restore_temp="$2/$1"
if [ ! -e "${restore_temp}" ]
then
 write_log_restore "${restore_temp}" "4"
 echo -e "\033[31m还原配置文件${restore_temp}出错 \033[0m\n"
 exit 1
fi

restore_num=0
restore_suc=0
while read line
do
    restore_num=`expr $restore_num + 1`
    restore_file=$(echo $line |cut -d "|" -f 2 |cut -d : -f 2)
    restore_file_original=$(echo $restore_file | sed 's/.backup//')
    if [ -e "${restore_file}" ]
	then
    echo "开始还原文件${restore_file_original}"
	rm "${restore_file_original}"
	cp -a "${restore_file}" "${restore_file_original}"
	rm "${restore_file}"
	  if [ -e "${restore_file_original}" ]
        then
          if [ ! -e "${restore_file}" ]	
            then
			  cat restore |sed "s#$line##" |sed '/^$/d' > restore.2
			  cp restore.2 restore
			  write_log_restore "${restore_file_original}" "1" 
			  restore_suc=`expr $restore_suc + 1`
			  echo "还原文件${restore_file_original}成功"
			else
			  cat restore |sed "s#$line##" |sed '/^$/d' > restore.2
			  cp restore.2 restore
			  write_log_restore "${restore_file_original}" "2"
			  restore_suc=`expr $restore_suc + 1`
			  echo -e "还原文件${restore_file_original}成功，\033[31m但是${restore_file}仍存在\033[0m\n" 
		  fi
		else
		write_log_restore "${restore_file_original}" "5" 
	    echo -e "\033[31m还原文件${restore_file_original}失败\033[0m\n"
      fi
    else
	write_log_restore "${restore_file_original}" "3"
	echo -e "\033[31m尝试还原文件${restore_file_original}，无法还原，${restore_file}不存在\033[0m\n"
	fi
done < $restore_temp
cat restore |cut -d "|" -f 1 |cut -d : -f 2 |sort |uniq |awk '{print "("FNR") "$0}' > restoremodule
restoremodulecount=$(cat restore |cut -d "|" -f 1 |cut -d : -f 2 |sort |uniq |wc -l)

}




while [ "$flag" -eq 0 ]
do
echo "========================================"
echo "          欢迎使用打点补丁程序          "
echo "========================================"
cat << EOF
|-----------System Infomation-----------
| DATE       :$DATE
| HOSTNAME   :$HOSTNAME
| USER       :$USER
| IP         :$IPADDR
| DISK_USED  :$DISK_SDA
| CPU_AVERAGE:$cpu_uptime
----------------------------------------
|*******请输入需要的操作:[0-2]*********|
----------------------------------------
(1) 应用打点
(2) 打点还原
(3) 设置openstack客户端的路径
(0) 退出
EOF

read -p "请输入需要的操作：[0-2]: " input

case $input in



#1应用打点
1)
clear
while [ "$flag" -eq 0 ]
do

echo "========================================"
echo "          打点模块如下所示：            "
echo "========================================"

while read line
do
    echo $line
done < patchmodule
echo "(0) 返回"

cat << EOF
-----------------------------------------------
|*******请输入需要打点的模块:[0-$count]*******|
-----------------------------------------------
EOF

 read -p "请输入需要打点的模块:[0-$count]: " input1
 
 if [[ ! "$input1" =~ ^[0-9]+$ ]]
  then
  echo_error
  elif [ $input1 -lt 0 -o $input1 -gt $count ]
  then
  echo_error
  elif [ $input1 -eq 0 ]
  then
  clear 
  break
  else 
  to_patch $input1
 fi

done
;;



#2打点还原
2)
clear

if [ ! -e restore ]
then
while [ "$flag" -eq 0 ]
do
  echo_nopatch
done
fi

if [ -e restore ]
then
cat restore |cut -d "|" -f 1 |cut -d : -f 2 |sort |uniq |awk '{print "("FNR") "$0}' > restoremodule
restoremodulecount=$(cat restore |cut -d "|" -f 1 |cut -d : -f 2 |sort |uniq |wc -l)

while [ "$flag" -eq 0 ]
do
if [ $restoremodulecount -eq 0 ]
then
  echo_nopatch
  
else

echo "========================================"
echo "     在本机已打点的模块如下所示：       "
echo "========================================"

while read line
do
    echo $line
done < restoremodule
echo "(0) 返回"

cat << EOF
-----------------------------------------------
|*******请输入需要还原的模块:[0-$restoremodulecount]*******|
-----------------------------------------------
EOF

 read -p "请输入需要还原的模块:[0-$restoremodulecount]: " input3
 
 
 if [[ ! "$input3" =~ ^[0-9]+$ ]]
  then
  echo_error
  elif [ $input3 -lt 0 -o $input3 -gt $restoremodulecount ]
  then
  echo_error
  elif [ $input3 -eq 0 ]
  then
  clear 
  break
  else 
  to_restore $input3
 fi
 
fi
done
fi

;;



0)
clear
exit 0
;;


*)  
echo_error
;;
esac
done

