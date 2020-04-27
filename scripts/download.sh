#!/bin/bash -x

token=kingsd041:88c81fd04e36d40dd9b3570c88450eb521aa7cac

download_dir="/usr/share/nginx/html/download"

## Rancher RKE
rke_download()
{   
    repo=rancher/rke
    
    version=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/git/refs/tags | jq -r .[].ref | awk -F/ '{print $3}' | grep v | awk -Fv '{print $2}' | grep -v [a-z] | awk -F"." '{arr[$1"."$2]=$3}END{for(var in arr){if(arr[var]==""){print var}else{print var"."arr[var]}}}' | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3 )

    for ver in $version;
    do

        mkdir -p $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver

        file_name=$(curl -LSs -u $token -s https://api.github.com/repos/$repo/releases/tags/v$ver | jq -r .assets[].browser_download_url | awk -F/v$ver/ '{print $2}'  )

        for file in $file_name;
        do  
            curl -LSs https://github.com/$repo/releases/download/v$ver/$file -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver/$file
        done
    done
}

## Rancher CLI
cli_download()
{   
    repo=rancher/cli

    version=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/git/refs/tags | jq -r .[].ref | awk -F/ '{print $3}' | grep v | awk -Fv '{print $2}' | grep -v [a-z] | awk -F"." '{arr[$1"."$2]=$3}END{for(var in arr){if(arr[var]==""){print var}else{print var"."arr[var]}}}' | sort -r -u -t "." -k1n,1 -k2n,2 -k3n,3 | grep -vw ^0.[0-5] )
          
    for ver in $version;
    do

        mkdir -p $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver

        file_name=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/releases/tags/v$ver | jq -r .assets[].browser_download_url | awk -F"/v$ver/" '{print $2}' )

        for file in $file_name;
        do
            curl -LSs https://github.com/$repo/releases/download/v$ver/$file -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver/$file
        done
    done
}

## Rancher
rancher_assets_download()
{   
    repo=rancher/rancher
    
    version=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/git/refs/tags | jq -r .[].ref | awk -F/ '{print $3}' | grep v | awk -Fv '{print $2}' | grep -v [a-z] | awk -F"." '{arr[$1"."$2]=$3}END{for(var in arr){if(arr[var]==""){print var}else{print var"."arr[var]}}}' | awk -F '.' '{if ($1>=2) print $0}' | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3 )

    for ver in $version;
    do
        mkdir -p $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver

        file_name=$(curl -LSs -u $token -s https://api.github.com/repos/$repo/releases/tags/v$ver | jq -r .assets[].browser_download_url | awk -F/v$ver/ '{print $2}' )

        for file in $file_name;
        do  
            curl -LSs https://github.com/$repo/releases/download/v$ver/$file -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver/$file
        done
    done
}



### rancher charts
rancher_charts_download()
{
    cd /root
    curl -LSs -O https://get.helm.sh/helm-`curl https://api.github.com/repos/helm/helm/releases/latest | jq .tag_name -r`-linux-amd64.tar.gz
    tar -zxf helm*.tar.gz
    cd linux-amd64
    cp helm /usr/local/bin/helm
    chmod +x /usr/local/bin/helm
    cd /root

    repo=rancher/rancher
    version=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/git/refs/tags | jq -r .[].ref | awk -F/ '{print $3}' | grep v | awk -Fv '{print $2}' | grep -v [a-z] | sort -u -t "." -k1nr,1 -k2nr,2 -k3nr,3 | grep -v ^0. | grep -v ^1. | grep -vwE '2.0.0|2.0.1|2.0.2|2.0.3')

    helm init --client-only
    helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
    helm repo update

    for ver in $version;
    do
        mkdir -p $download_dir/`echo $repo | awk -F/ '{ print $2 }'`-charts/
        helm fetch rancher-latest/rancher --version v$ver -d $download_dir/`echo $repo | awk -F/ '{ print $2 }'`-charts/
    done

    # rm -rf /root/helm*.tar.gz /root/linux-amd64
}

## 
urlencode() {
    local LANG=C
    local length="${#1}"
    i=0
    while :
    do
        [ $length -gt $i ]&&{
        local c="${1:$i:1}"
            case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
            esac
        }||break
        let i++
    done
}

## k3s

k3s_download()
{
    repo=rancher/k3s

    version=$( curl -LSs https://update.k3s.io/v1-release/channels | jq -r ".data[].latest"  | grep v  | grep -v "rc" | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3)

    for ver in $version;
    do

        mkdir -p $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/$ver
        ver1=`urlencode "$ver"`
        file_name=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/releases/tags/$ver | jq -r .assets[].browser_download_url | awk -F/$ver1/ '{print $2}'  )

        for file in $file_name;
        do
            curl -LSs https://github.com/$repo/releases/download/$ver/$file -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/$ver/$file
        done
    done
}


k3s_install()
{
    repo=xiaoluhong/k3s
    mkdir -p $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/
    curl https://raw.githubusercontent.com/xiaoluhong/k3s/master/install.sh -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/k3s-install.sh
}


rke_download
cli_download
rancher_assets_download
rancher_charts_download
k3s_download
k3s_install
