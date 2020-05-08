#!/bin/bash
set -x
token=$1

download_dir="/opt/rancher-mirror"

oss_bucket_name="rancher-mirror"

# Used to compare the release version with the aliyun oss version
compare_version()
{
    release_v=$1
    oss_v=$2
    new_version=""
    for v in $release_v
    do
        if [[ ! "$oss_v" =~ "$v" ]];then
            new_version="$new_version $v"
        else
            echo "`date '+%F %T %A'`:  `echo $repo | awk -F/ '{ print $2 }'` v$v already exists in aliyun oss"
        fi
    done
    [[ -n $new_version ]] && echo "`date '+%F %T %A'`:  Downloading `echo $repo | awk -F/ '{ print $2 }'` $new_version ..."
}


## Rancher RKE
rke_download()
{
    repo=rancher/rke

    version=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/git/refs/tags | jq -r .[].ref | awk -F/ '{print $3}' | grep v | awk -Fv '{print $2}' | grep -v [a-z] | awk -F"." '{arr[$1"."$2]=$3}END{for(var in arr){if(arr[var]==""){print var}else{print var"."arr[var]}}}' | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3 )

    oss_version=$(/usr/local/bin/ossutil --config-file=/root/.ossutilconfig ls oss://$oss_bucket_name/`echo $repo | awk -F/ '{ print $2 }'`/ -d | awk -F "\/" '{print $5}'  | grep v | sed 's/.//' | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3)

    compare_version "$version" "$oss_version"

    for ver in $new_version;
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

    oss_version=$(/usr/local/bin/ossutil --config-file=/root/.ossutilconfig ls oss://$oss_bucket_name/`echo $repo | awk -F/ '{ print $2 }'`/ -d | awk -F "\/" '{print $5}'  | grep v | sed 's/.//' | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3)

    compare_version "$version" "$oss_version"

    for ver in $new_version;
    do

        mkdir -p $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver

        file_name=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/releases/tags/v$ver | jq -r .assets[].browser_download_url | awk -F"/v$ver/" '{print $2}' )

        for file in $file_name;
        do
            curl -LSs https://github.com/$repo/releases/download/v$ver/$file -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver/$file
        done
    done
}

## Rancher release assets
rancher_assets_download()
{
    repo=rancher/rancher

    version=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/git/refs/tags | jq -r .[].ref | awk -F/ '{print $3}' | grep v | awk -Fv '{print $2}' | grep -v [a-z] | awk -F"." '{arr[$1"."$2]=$3}END{for(var in arr){if(arr[var]==""){print var}else{print var"."arr[var]}}}' | awk -F '.' '{if ($1>=2) print $0}' | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3 )

    oss_version=$(/usr/local/bin/ossutil --config-file=/root/.ossutilconfig ls oss://$oss_bucket_name/`echo $repo | awk -F/ '{ print $2 }'`/ -d | awk -F "\/" '{print $5}'  | grep v | sed 's/.//' | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3)

    compare_version "$version" "$oss_version"

    for ver in $new_version;
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

    #oss_version=$(/usr/local/bin/ossutil --config-file=/root/.ossutilconfig ls oss://$oss_bucket_name/`echo $repo | awk -F/ '{ print $2 }'`/ -d | awk -F "\/" '{print $5}'  | grep v | sed 's/.//' | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3)
    oss_version=$(/usr/local/bin/ossutil --config-file=/root/.ossutilconfig ls oss://$oss_bucket_name/rancher-charts/ | awk -F "\/" '{print $5}' | grep -v "^$" | awk -F "-" '{print $2}' | awk -F "." '{print $1"."$2"."$3}' | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3)

    compare_version "$version" "$oss_version"

    for ver in $new_version;
    do
        mkdir -p $download_dir/`echo $repo | awk -F/ '{ print $2 }'`-charts/
        helm fetch rancher-latest/rancher --version v$ver -d $download_dir/`echo $repo | awk -F/ '{ print $2 }'`-charts/
    done

    rm -rf /root/helm*.tar.gz /root/linux-amd64
}

## URL encode
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

urldecode(){
u="${1//+/ }"
echo -e "${u//%/\\x}"
}

## k3s

k3s_download()
{
    repo=rancher/k3s

    version=$( curl -LSs https://update.k3s.io/v1-release/channels | jq -r ".data[].latest"  | grep v  | grep -v "rc" | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3)

    oss_version=$(/usr/local/bin/ossutil --config-file=/root/.ossutilconfig ls oss://$oss_bucket_name/`echo $repo | awk -F/ '{ print $2 }'`/ -d | awk -F "\/" '{print $5}'  | grep v | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3)

    #version_urlencode=""
    for ver in $version
    do
	ver1=`urlencode "$ver"`
        version_urlencode="$version_urlencode $ver1"
    done

    for oss_ver in $oss_version
    do
	oss_ver1=`urlencode "$oss_ver"`
        oss_version_urlencode="$oss_version_urlencode $oss_ver1"
    done
    compare_version "$version_urlencode" "$oss_version_urlencode"

    new_version=`urldecode "$new_version"`

    for ver in $new_version;
    do
        mkdir -p $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/$ver
        file_name=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/releases/tags/$ver | jq -r .assets[].browser_download_url | awk -F "\/" '{print $NF}'  )

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

## Kubectl
kubectl_download()
{
    repo=kubernetes/kubernetes

    version=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/git/refs/tags | jq -r .[].ref | awk -F/ '{print $3}' | grep v | awk -Fv '{print $2}' | grep -v [a-z] | awk -F"." '{arr[$1"."$2]=$3}END{for(var in arr){if(arr[var]==""){print var}else{print var"."arr[var]}}}'|sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3 | grep -v ^0. | grep -vw ^1.[0-5] )

    oss_version=$(/usr/local/bin/ossutil --config-file=/root/.ossutilconfig ls oss://$oss_bucket_name/kubectl/ -d | awk -F "\/" '{print $5}'  | grep v | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3)

    compare_version "$version" "$oss_version"

    for ver in $new_version;
    do
        mkdir -p $download_dir/kubectl/v$ver
        curl -LSs https://storage.googleapis.com/kubernetes-release/release/v$ver/bin/linux/amd64/kubectl -o $download_dir/kubectl/v$ver/linux-amd64-v$ver-kubectl
        curl -LSs https://storage.googleapis.com/kubernetes-release/release/v$ver/bin/darwin/amd64/kubectl -o $download_dir/kubectl/v$ver/darwin-amd64-v$ver-kubectl
        curl -LSs https://storage.googleapis.com/kubernetes-release/release/v$ver/bin/windows/amd64/kubectl.exe -o $download_dir/kubectl/v$ver/windows-amd64-v$ver-kubectl.exe
    done
}

## Docker-compose
compose_download()
{
    repo=docker/compose

    version=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/git/refs/tags | jq -r .[].ref | awk -F/ '{print $3}' | grep -v [a-z] | awk -F"." '{arr[$1"."$2]=$3}END{for(var in arr){if(arr[var]==""){print var}else{print var"."arr[var]}}}' | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3 | grep -v ^0. | grep -vw ^1.[0-9] )

    oss_version=$(/usr/local/bin/ossutil --config-file=/root/.ossutilconfig ls oss://$oss_bucket_name/`echo $repo | awk -F/ '{ print $1 }'`-`echo $repo | awk -F/ '{ print $2 }'` |  awk -F "\/" '{print $5}' | grep v | sed 's/.//' | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3)

    compare_version "$version" "$oss_version"

    for ver in $new_version;
    do
        mkdir -p $download_dir/`echo $repo | awk -F/ '{ print $1 }'`-`echo $repo | awk -F/ '{ print $2 }'`/v$ver
        file_name=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/releases/tags/$ver | jq -r .assets[].browser_download_url | awk -F"/$ver/" '{print $2}' | grep -v sha256sum | grep -v run.sh | grep -v sha256 )

        for file in $file_name;
        do
            curl -LSs https://github.com/$repo/releases/download/$ver/$file -o $download_dir/`echo $repo | awk -F/ '{ print $1 }'`-`echo $repo | awk -F/ '{ print $2 }'`/v$ver/$file
        done
    done
}

## Harbor
harbor_download()
{
    repo=goharbor/harbor

    version=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/git/refs/tags | jq -r .[].ref | grep v | awk -F/ '{print $3}' |  awk -Fv '{print $2}' | grep -v [a-z] | awk -F"." '{arr[$1"."$2]=$3}END{for(var in arr){if(arr[var]==""){print var}else{print var"."arr[var]}}}' | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3 | grep -vw ^1.[0-5] )

    oss_version=$(/usr/local/bin/ossutil --config-file=/root/.ossutilconfig ls oss://$oss_bucket_name/`echo $repo | awk -F/ '{ print $2 }'`/ -d | awk -F "\/" '{print $5}'  | grep v | sed 's/.//' | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3)

    compare_version "$version" "$oss_version"

    for ver in $new_version;
    do
        mkdir -p $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver
        curl -LSs https://storage.googleapis.com/harbor-releases/release-`echo $ver | awk -F. '{ print $1"."$2 }'`.0/harbor-online-installer-v$ver.tgz -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver/harbor-online-installer-v$ver.tgz
    done
}


rke_download
cli_download
rancher_assets_download
rancher_charts_download
k3s_download
k3s_install
kubectl_download
compose_download
harbor_download