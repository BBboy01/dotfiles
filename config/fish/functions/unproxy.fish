function unproxy
    set -gu http_proxy
    set -gu https_proxy
    set -gu all_proxy
end
