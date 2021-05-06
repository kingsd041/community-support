#!/bin/bash
#set -x
set -e

# export https_proxy=http://127.0.0.1:1087 http_proxy=http://127.0.0.1:1087 all_proxy=socks5://127.0.0.1:1087

token=$1

download_dir="/opt/rancher-mirror"

oss_bucket_name="rancher-mirror"

# 测试oss是否可用
oss_test=`/usr/local/bin/ossutil --config-file=/root/.ossutilconfig ls oss://$oss_bucket_name`
if [[ $oss_test =~ 'Error' ]]; then
    exit 1
fi

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
    #[[ -n $new_version ]] && echo "`date '+%F %T %A'`:  Downloading `echo $repo | awk -F/ '{ print $2 }'` $new_version ..."
    if [[ -n $new_version ]]; then
        echo "`date '+%F %T %A'`:  Downloading `echo $repo | awk -F/ '{ print $2 }'` $new_version ..."
    else
        echo "`date '+%F %T %A'`:  `echo $repo | awk -F/ '{ print $2 }'` does not have the latest version to download..."
    fi
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
    chart_url="https://releases.rancher.com/server-charts"

    releases_version="stable latest alpha"

    for r_ver in $releases_version
    do
        version=$( curl -LSs  $chart_url/$r_ver/index.yaml | grep version | awk '{print $2}'  )
        oss_version=$( /usr/local/bin/ossutil --config-file=/root/.ossutilconfig ls oss://$oss_bucket_name/server-charts/$r_ver | awk -F "\/" '{print $6}' | grep -v "^$" | awk -F "." '{print $1"."$2"."$3}' | grep [0-9] | sort -r  -u )

        compare_version "$version" "$oss_version"

        mkdir -p $download_dir/server-charts/$r_ver

        for ver in $new_version;
        do
            curl -LSs $chart_url/$r_ver/rancher-$ver.tgz -o $download_dir/server-charts/$r_ver/rancher-$ver.tgz
        done
        curl -LSs $chart_url/$r_ver/index.yaml -o $download_dir/server-charts/$r_ver/index.yaml

    # 由于compare_version的bug(rancher-2.4.5-rc1 包含 rancher-2.4.5，导致在latest里没有rancher-2.4.5的chart), 所以临时处理下，将stable里的chart复制到latest
    if [ $r_ver = 'latest' ]; then
            awk 'BEGIN { cmd="cp -i /opt/rancher-mirror/server-charts/stable/rancher-* /opt/rancher-mirror/server-charts/latest/"; print "n" |cmd; }'
        fi
    done
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
    repo=k3s-io/k3s

    #version=$( curl -LSs https://update.k3s.io/v1-release/channels | jq -r ".data[].latest"  | grep v  | grep -v "rc" | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3)
    version=$( curl -LSs https://update.k3s.io/v1-release/channels | jq -r ".data[].latest"  | grep v  | grep -v "rc" | sort -r  -u )

    version=$( echo ${version} | sed 's/+/-/g' )

    oss_version=$(/usr/local/bin/ossutil --config-file=/root/.ossutilconfig ls oss://$oss_bucket_name/`echo $repo | awk -F/ '{ print $2 }'`/ -d | awk -F "\/" '{print $5}'  | grep v | sort -r  -u )

    #version_urlencode=""
    # for ver in $version
    # do
    # ver1=`urlencode "$ver"`
    #     version_urlencode="$version_urlencode $ver1"
    # done

    # for oss_ver in $oss_version
    # do
    # oss_ver1=`urlencode "$oss_ver"`
    #     oss_version_urlencode="$oss_version_urlencode $oss_ver1"
    # done
    compare_version "$version" "$oss_version"

    # new_version=`urldecode "$new_version"`

    for ver in $new_version;
    do
        init_var=$( echo ${ver} | sed 's/-/+/g' )
        mkdir -p $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/$ver
        file_name=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/releases/tags/$init_var | jq -r .assets[].browser_download_url | awk -F "\/" '{print $NF}'  )

        for file in $file_name;
        do
          curl -LSs https://github.com/$repo/releases/download/$init_var/$file -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/$ver/$file
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
#        curl -LSs https://storage.googleapis.com/harbor-releases/release-`echo $ver | awk -F. '{ print $1"."$2 }'`.0/harbor-offline-installer-v$ver.tgz -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver/harbor-online-installer-v$ver.tgz
    done
}

## Helm
helm_download()
{
    repo=helm/helm

    version=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/git/refs/tags | jq -r .[].ref | awk -F/ '{print $3}' | grep v | awk -Fv '{print $2}' | grep -v [a-z] | awk -F"." '{arr[$1"."$2]=$3}END{for(var in arr){if(arr[var]==""){print var}else{print var"."arr[var]}}}' | grep -vw ^[1] | sort -u -t "." -k1nr,1 -k2nr,2 -k3nr,3 | awk -F '.' '!a[$1]++{print}' )

    oss_version=$(/usr/local/bin/ossutil --config-file=/root/.ossutilconfig ls oss://$oss_bucket_name/`echo $repo | awk -F/ '{ print $2 }'`/ -d | awk -F "\/" '{print $5}'  | grep v | sed 's/.//' | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3)

    compare_version "$version" "$oss_version"

    for ver in $new_version;
    do
    mkdir -p $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver
        curl -LSs https://get.helm.sh/helm-v$ver-darwin-amd64.tar.gz -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver/helm-v$ver-darwin-amd64.tar.gz
        curl -LSs https://get.helm.sh/helm-v$ver-linux-amd64.tar.gz -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver/helm-v$ver-linux-amd64.tar.gz
#        curl -LSs https://get.helm.sh/helm-v$ver-linux-arm.tar.gz -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver/helm-v$ver-linux-arm.tar.gz
        curl -LSs https://get.helm.sh/helm-v$ver-linux-arm64.tar.gz -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver/helm-v$ver-linux-arm64.tar.gz
#        curl -LSs https://get.helm.sh/helm-v$ver-linux-386.tar.gz -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver/helm-v$ver-linux-386.tar.gz
#        curl -LSs https://get.helm.sh/helm-v$ver-linux-ppc64le.tar.gz -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver/helm-v$ver-linux-ppc64le.tar.gz
#        curl -LSs https://get.helm.sh/helm-v$ver-linux-s390x.tar.gz -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver/helm-v$ver-linux-s390x.tar.gz
        curl -LSs https://get.helm.sh/helm-v$ver-windows-amd64.zip -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver/helm-v$ver-windows-amd64.zip
    done
}

## Rancher K3D
k3d_download()
{
    repo=rancher/k3d

    version=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/git/refs/tags | jq -r .[].ref | awk -F/ '{print $3}' | grep v | awk -Fv '{print $2}' | grep -v [a-z] | awk -F"." '{arr[$1"."$2]=$3}END{for(var in arr){if(arr[var]==""){print var}else{print var"."arr[var]}}}' | grep -vw ^[0] | sort -u -t "." -k1nr,1 -k2nr,2 -k3nr,3 | awk -F '.' '!a[$1]++{print}' )

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

## Rancher Octopus

octopus_download()
{
    repo=cnrancher/octopus
    adaptor_files="modbus opcua mqtt ble dummy"

    # Download YAML for the Master branch
    rm -rf /tmp/octopus
    git clone https://github.com/cnrancher/octopus.git /tmp/octopus

    mkdir -p $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/master/deploy/e2e/

    cp -rf /tmp/octopus/deploy/e2e/*.yaml $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/master/deploy/e2e/

    adaptors_dir=`ls /tmp/octopus/adaptors`

    for adaptor_dir in $adaptors_dir
    do
        mkdir -p $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/master/adaptors/$adaptor_dir/deploy/e2e/
        cp -rf /tmp/octopus/adaptors/$adaptor_dir/deploy/e2e/*.yaml $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/master/adaptors/$adaptor_dir/deploy/e2e/
    done

    curl -LSs --create-dirs https://raw.githubusercontent.com/cnrancher/octopus-api-server/master/deploy/e2e/all_in_one.yaml -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/api-server/master/deploy/e2e/all_in_one.yaml

    # Download YAML from Release
    version=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/git/refs/tags | jq -r .[].ref | awk -F/ '{print $3}' | grep v | awk -Fv '{print $2}' | grep -v [a-z] | awk -F"." '{arr[$1"."$2]=$3}END{for(var in arr){if(arr[var]==""){print var}else{print var"."arr[var]}}}' | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3 | grep -vw ^0.[0-9] )
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

k3s_channels()
{
    k3s_channel_dir=$download_dir/k3s/channels/
    mkdir -p $k3s_channel_dir
    INSTALL_K3S_CHANNEL_URL=${INSTALL_K3S_CHANNEL_URL:-'https://update.k3s.io/v1-release/channels'}
    INSTALL_K3S_CHANNELS="stable latest testing"
    for INSTALL_K3S_CHANNEL in $INSTALL_K3S_CHANNELS;
    do
        version_url="${INSTALL_K3S_CHANNEL_URL}/${INSTALL_K3S_CHANNEL}"
        VERSION_K3S=$(curl -w '%{url_effective}' -L -s -S ${version_url} -o /dev/null | sed -e 's|.*/||')
        echo $VERSION_K3S > $k3s_channel_dir/$INSTALL_K3S_CHANNEL
    done
}

## Rancher harvester
harvester_download()
{
    repo=rancher/harvester

    version=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/git/refs/tags | jq -r .[].ref | awk -F/ '{print $3}' | grep v | awk -Fv '{print $2}' | grep -v [a-z] | awk -F"." '{arr[$1"."$2]=$3}END{for(var in arr){if(arr[var]==""){print var}else{print var"."arr[var]}}}' | grep -vw ^[0].[0] | sort -u -t "." -k1nr,1 -k2nr,2 -k3nr,3 | awk -F '.' '!a[$1]++{print}' )

    oss_version=$(/usr/local/bin/ossutil --config-file=/root/.ossutilconfig ls oss://$oss_bucket_name/`echo $repo | awk -F/ '{ print $2 }'`/ -d | awk -F "\/" '{print $5}'  | grep v | sed 's/.//' | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3)

    compare_version "$version" "$oss_version"

    for ver in $new_version;
    do

        mkdir -p $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver

        # file_name=$(curl -LSs -u $token -s https://api.github.com/repos/$repo/releases/tags/v$ver | jq -r .assets[].browser_download_url | awk -F/v$ver/ '{print $2}'  )
        file_name="harvester-amd64.iso harvester-initrd-amd64 harvester-vmlinuz-amd64"

        for file in $file_name;
        do
            # curl -LSs https://github.com/$repo/releases/download/v$ver/$file -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver/$file
            curl -LSs https://releases.rancher.com/harvester/v$ver/$file -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/v$ver/$file
        done
    done
}

# autok3s
autok3s_download()
{
    repo=cnrancher/autok3s

    version=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/git/refs/tags | jq -r .[].ref | awk -F/ '{print $3}' | grep v | awk -Fv '{print $2}' | grep -v [a-z] | awk -F"." '{arr[$1"."$2]=$3}END{for(var in arr){if(arr[var]==""){print var}else{print var"."arr[var]}}}'  | sort -u -t "." -k1nr,1 -k2nr,2 -k3nr,3 | awk -F '.' '!a[$1]++{print}' )

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

# autok3s channels
autok3s_channels()
{
    autok3s_channel_dir=$download_dir/autok3s/channels
    mkdir -p $autok3s_channel_dir
    INSTALL_AUTOK3S_CHANNEL_URL=${INSTALL_AUTOK3S_CHANNEL_URL:-'https://github.com/cnrancher/autok3s/releases'}
    INSTALL_AUTOK3S_CHANNELS="latest"
    for INSTALL_AUTOK3S_CHANNEL in $INSTALL_AUTOK3S_CHANNELS;
    do
        version_url="${INSTALL_AUTOK3S_CHANNEL_URL}/${INSTALL_AUTOK3S_CHANNEL}"
        VERSION_AUTOK3S=$(curl -w '%{url_effective}' -L -s -S ${version_url} -o /dev/null | sed -e 's|.*/||')
        echo $VERSION_AUTOK3S > $autok3s_channel_dir/$INSTALL_AUTOK3S_CHANNEL
    done
}

## Rancher RKE2
rke2_download()
{
    repo=rancher/rke2

    version=$( curl -LSs -u $token -s https://api.github.com/repos/$repo/git/refs/tags | jq -r .[].ref | awk -F/ '{print $3}' | grep v | awk -Fv '{print $2}' | grep -v rc[0-9] | grep -v alpha | awk -F"." '{arr[$1"."$2]=$3}END{for(var in arr){if(arr[var]==""){print var}else{print var"."arr[var]}}}' | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3 )

    version=$( echo ${version} | sed 's/+/-/g' )

    oss_version=$(/usr/local/bin/ossutil --config-file=/root/.ossutilconfig ls oss://$oss_bucket_name/`echo $repo | awk -F/ '{ print $2 }'`/releases/download/ -d | awk -F "/" '{print $7}'  | grep v | sed 's/.//' | sort -r  -u -t "." -k1n,1 -k2n,2 -k3n,3)

    compare_version "$version" "$oss_version"

    for ver in $new_version;
    do
        init_var=$( echo ${ver} | sed 's/-/+/g' )
        
        mkdir -p $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/releases/download/v$ver

        file_name=$(curl -LSs -u $token -s https://api.github.com/repos/$repo/releases/tags/v$init_var | jq -r .assets[].browser_download_url | awk -F "/" '{print $NF}' )

        for file in $file_name;
        do
            curl -LSs https://github.com/$repo/releases/download/v$init_var/$file -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/releases/download/v$ver/$file
        done
    done
}

rke2_channels()
{
    rke2_channel_dir=$download_dir/rke2/channels
    mkdir -p $rke2_channel_dir
    INSTALL_RKE2_CHANNEL_URL=${INSTALL_RKE2_CHANNEL_URL:-'https://update.rke2.io/v1-release/channels'}
    INSTALL_RKE2_CHANNELS="stable latest testing v1.18  v1.19"
    for INSTALL_RKE2_CHANNEL in $INSTALL_RKE2_CHANNELS;
    do
        version_url="${INSTALL_RKE2_CHANNEL_URL}/${INSTALL_RKE2_CHANNEL}"
        VERSION_RKE2=$(curl -w '%{url_effective}' -L -s -S ${version_url} -o /dev/null | sed -e 's|.*/||')
        echo $VERSION_RKE2 > $rke2_channel_dir/$INSTALL_RKE2_CHANNEL
    done
}

rke2_install()
{
    repo=kingsd041/rke2
    mkdir -p $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/
    curl https://raw.githubusercontent.com/kingsd041/rke2/master/install.sh -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/install.sh
}

autok3s_install()
{
    repo=cnrancher/autok3s
    mkdir -p $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/
    curl https://raw.githubusercontent.com/$repo/master/hack/lib/install.sh -o $download_dir/`echo $repo | awk -F/ '{ print $2 }'`/install.sh
}

output_download_result()
{
    echo "`date '+%F %T %A'`:  Download the required resources successfully !!!"
}

rke_download
cli_download
rancher_assets_download
rancher_charts_download
k3s_download
k3s_install
k3s_channels
kubectl_download
#compose_download
harbor_download
helm_download
k3d_download
octopus_download
harvester_download
autok3s_download
autok3s_channels
rke2_download
rke2_channels
rke2_install
autok3s_install

output_download_result
