2026-07-23T09:29:01.3228077Z Current runner version: '2.336.0'
2026-07-23T09:29:01.3251766Z ##[group]Runner Image Provisioner
2026-07-23T09:29:01.3252841Z Hosted Compute Agent
2026-07-23T09:29:01.3253535Z Version: 20260707.563
2026-07-23T09:29:01.3254547Z Commit: 02667638d2b423fbc733a8e32a88b44996a3ba6e
2026-07-23T09:29:01.3255385Z Build Date: 2026-07-07T19:33:50Z
2026-07-23T09:29:01.3256173Z Worker ID: {0e60e031-02fd-488c-877c-7dfd0b358118}
2026-07-23T09:29:01.3257081Z Azure Region: centralus
2026-07-23T09:29:01.3257779Z ##[endgroup]
2026-07-23T09:29:01.3259158Z ##[group]Operating System
2026-07-23T09:29:01.3259908Z Ubuntu
2026-07-23T09:29:01.3260629Z 24.04.4
2026-07-23T09:29:01.3261293Z LTS
2026-07-23T09:29:01.3261940Z ##[endgroup]
2026-07-23T09:29:01.3262624Z ##[group]Runner Image
2026-07-23T09:29:01.3263451Z Image: ***-24.04
2026-07-23T09:29:01.3264460Z Version: 20260714.240.1
2026-07-23T09:29:01.3265867Z Included Software: https://github.com/actions/runner-images/blob/***24/20260714.240/images/***/Ubuntu2404-Readme.md
2026-07-23T09:29:01.3267454Z Image Release: https://github.com/actions/runner-images/releases/tag/***24%2F20260714.240
2026-07-23T09:29:01.3268579Z ##[endgroup]
2026-07-23T09:29:01.3269927Z ##[group]GITHUB*TOKEN Permissions
2026-07-23T09:29:01.3273051Z Contents: read
2026-07-23T09:29:01.3274108Z Metadata: read
2026-07-23T09:29:01.3274977Z Packages: read
2026-07-23T09:29:01.3275884Z ##[endgroup]
2026-07-23T09:29:01.3278324Z Secret source: Actions
2026-07-23T09:29:01.3279622Z Prepare workflow directory
2026-07-23T09:29:01.3695116Z Prepare all required actions
2026-07-23T09:29:01.3731189Z Getting action download info
2026-07-23T09:29:01.6157189Z Download action repository 'actions/checkout@v5' (SHA:fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09)
2026-07-23T09:29:02.4412474Z Download action repository 'appleboy/scp-action@v0.1.7' (SHA:917f8b81dfc1ccd331fef9e2d61bdc6c8be94634)
2026-07-23T09:29:02.6339533Z Download action repository 'appleboy/ssh-action@v1.1.0' (SHA:25ce8cbbcb08177468c7ff7ec5cbfa236f9341e1)
2026-07-23T09:29:03.0611592Z Complete job name: Deploy to Server
2026-07-23T09:29:03.1026986Z ##[group]Build container for action use: '/home/runner/work/\_actions/appleboy/scp-action/v0.1.7/Dockerfile'.
2026-07-23T09:29:03.1063147Z ##[command]/usr/bin/docker build -t 0bc575:deaaf6ba02864a559e0b2bb6e664b3a2 -f "/home/runner/work/\_actions/appleboy/scp-action/v0.1.7/Dockerfile" "/home/runner/work/\_actions/appleboy/scp-action/v0.1.7"
2026-07-23T09:29:03.6455531Z #0 building with "default" instance using docker driver
2026-07-23T09:29:03.6457033Z
2026-07-23T09:29:03.6457735Z #1 [internal] load build definition from Dockerfile
2026-07-23T09:29:03.6459552Z #1 transferring dockerfile:
2026-07-23T09:29:03.8026313Z #1 transferring dockerfile: 150B done
2026-07-23T09:29:03.8027881Z #1 DONE 0.1s
2026-07-23T09:29:03.8028454Z
2026-07-23T09:29:03.8029245Z #2 [internal] load metadata for ghcr.io/appleboy/drone-scp:1.6.14
2026-07-23T09:29:04.7232835Z #2 DONE 1.1s
2026-07-23T09:29:04.8491263Z
2026-07-23T09:29:04.8493574Z #3 [internal] load .dockerignore
2026-07-23T09:29:04.8494999Z #3 transferring context: 2B done
2026-07-23T09:29:04.8495613Z #3 DONE 0.0s
2026-07-23T09:29:04.8495894Z
2026-07-23T09:29:04.8496139Z #4 [internal] load build context
2026-07-23T09:29:04.8496607Z #4 transferring context: 187B done
2026-07-23T09:29:04.8497082Z #4 DONE 0.0s
2026-07-23T09:29:04.8497822Z
2026-07-23T09:29:04.8498258Z #5 [1/2] FROM ghcr.io/appleboy/drone-scp:1.6.14@sha256:0e0597678b948b0aa09888c66ac75af904cce81baf6af955208527d259c61818
2026-07-23T09:29:04.8499006Z #5 resolve ghcr.io/appleboy/drone-scp:1.6.14@sha256:0e0597678b948b0aa09888c66ac75af904cce81baf6af955208527d259c61818 done
2026-07-23T09:29:04.8499711Z #5 sha256:1207c741d8c9b028d98c4006013f9de959da3c55f85b91ed5e4583438a0112ca 0B / 3.38MB 0.1s
2026-07-23T09:29:04.8500336Z #5 sha256:57fce42a8fe3138af514e9b1be611ec437fe87def8a6946cad1d6b7608188ce2 0B / 284.84kB 0.1s
2026-07-23T09:29:04.8501595Z #5 sha256:a7e706a435c2a53ff172ba5b50e2a06c2eaf63d2f764bdaabcca52d378beeb35 0B / 1.20kB 0.1s
2026-07-23T09:29:04.8502537Z #5 sha256:0e0597678b948b0aa09888c66ac75af904cce81baf6af955208527d259c61818 2.38kB / 2.38kB done
2026-07-23T09:29:04.8503215Z #5 sha256:b49e06fc857838320ee2682058d609a527fd05056650f6f6387b8a320d25aed5 1.24kB / 1.24kB done
2026-07-23T09:29:04.8504004Z #5 sha256:6e1933d0a1a550dee7c2be05d0c681372d8661e12dec2bd66f028fd3f2e1eccb 3.65kB / 3.65kB done
2026-07-23T09:29:04.9603418Z #5 sha256:1207c741d8c9b028d98c4006013f9de959da3c55f85b91ed5e4583438a0112ca 1.05MB / 3.38MB 0.2s
2026-07-23T09:29:04.9607467Z #5 sha256:a7e706a435c2a53ff172ba5b50e2a06c2eaf63d2f764bdaabcca52d378beeb35 1.20kB / 1.20kB 0.2s done
2026-07-23T09:29:05.1496261Z #5 sha256:1207c741d8c9b028d98c4006013f9de959da3c55f85b91ed5e4583438a0112ca 3.38MB / 3.38MB 0.3s done
2026-07-23T09:29:05.1497784Z #5 sha256:57fce42a8fe3138af514e9b1be611ec437fe87def8a6946cad1d6b7608188ce2 284.84kB / 284.84kB 0.3s done
2026-07-23T09:29:05.1498791Z #5 sha256:c5ff66ca7e6bad6eb2c1b483c6c580ef147d04552f3bba4b13ac1b05cf474013 125B / 125B 0.4s
2026-07-23T09:29:05.1499933Z #5 extracting sha256:1207c741d8c9b028d98c4006013f9de959da3c55f85b91ed5e4583438a0112ca
2026-07-23T09:29:05.3151392Z #5 extracting sha256:1207c741d8c9b028d98c4006013f9de959da3c55f85b91ed5e4583438a0112ca 0.1s done
2026-07-23T09:29:05.3152728Z #5 sha256:103b78775db928290fb85c370d3e47361a507a82b3b7c69c628783e018a9ffb8 0B / 2.49MB 0.5s
2026-07-23T09:29:05.3153804Z #5 extracting sha256:57fce42a8fe3138af514e9b1be611ec437fe87def8a6946cad1d6b7608188ce2
2026-07-23T09:29:05.4495515Z #5 sha256:c5ff66ca7e6bad6eb2c1b483c6c580ef147d04552f3bba4b13ac1b05cf474013 125B / 125B 0.5s done
2026-07-23T09:29:05.4497259Z #5 sha256:103b78775db928290fb85c370d3e47361a507a82b3b7c69c628783e018a9ffb8 2.49MB / 2.49MB 0.7s done
2026-07-23T09:29:05.4498883Z #5 extracting sha256:57fce42a8fe3138af514e9b1be611ec437fe87def8a6946cad1d6b7608188ce2 0.0s done
2026-07-23T09:29:05.7109218Z #5 extracting sha256:a7e706a435c2a53ff172ba5b50e2a06c2eaf63d2f764bdaabcca52d378beeb35
2026-07-23T09:29:05.8612683Z #5 extracting sha256:a7e706a435c2a53ff172ba5b50e2a06c2eaf63d2f764bdaabcca52d378beeb35 done
2026-07-23T09:29:05.9142178Z #5 extracting sha256:c5ff66ca7e6bad6eb2c1b483c6c580ef147d04552f3bba4b13ac1b05cf474013
2026-07-23T09:29:06.0382145Z #5 extracting sha256:c5ff66ca7e6bad6eb2c1b483c6c580ef147d04552f3bba4b13ac1b05cf474013 done
2026-07-23T09:29:06.0383202Z #5 extracting sha256:103b78775db928290fb85c370d3e47361a507a82b3b7c69c628783e018a9ffb8
2026-07-23T09:29:06.2179287Z #5 extracting sha256:103b78775db928290fb85c370d3e47361a507a82b3b7c69c628783e018a9ffb8 0.0s done
2026-07-23T09:29:06.2976773Z #5 DONE 1.6s
2026-07-23T09:29:06.4634071Z
2026-07-23T09:29:06.4635230Z #6 [2/2] COPY entrypoint.sh /bin/entrypoint.sh
2026-07-23T09:29:06.4636078Z #6 DONE 0.0s
2026-07-23T09:29:06.4636360Z
2026-07-23T09:29:06.4636542Z #7 exporting to image
2026-07-23T09:29:06.4636982Z #7 exporting layers
2026-07-23T09:29:07.0426683Z #7 exporting layers 0.7s done
2026-07-23T09:29:07.0692292Z #7 writing image sha256:f40316d5b6f732576ec8568bf3cc5734b1e45fb55c337c5b6fed80bea7adaba6 done
2026-07-23T09:29:07.0693450Z #7 naming to docker.io/library/0bc575:deaaf6ba02864a559e0b2bb6e664b3a2 done
2026-07-23T09:29:07.0694375Z #7 DONE 0.7s
2026-07-23T09:29:07.0738732Z ##[endgroup]
2026-07-23T09:29:07.0983485Z ##[group]Run actions/checkout@v5
2026-07-23T09:29:07.0984418Z with:
2026-07-23T09:29:07.0984821Z repository: EXE201-MenuGreen/MenuGreenSystem
2026-07-23T09:29:07.0987060Z token: \*\**
2026-07-23T09:29:07.0987456Z ssh-strict: true
2026-07-23T09:29:07.0987814Z ssh-user: git
2026-07-23T09:29:07.0988174Z persist-credentials: true
2026-07-23T09:29:07.0988571Z clean: true
2026-07-23T09:29:07.0988979Z sparse-checkout-cone-mode: true
2026-07-23T09:29:07.0989401Z fetch-depth: 1
2026-07-23T09:29:07.0989745Z fetch-tags: false
2026-07-23T09:29:07.0990104Z show-progress: true
2026-07-23T09:29:07.0990484Z lfs: false
2026-07-23T09:29:07.0990828Z submodules: false
2026-07-23T09:29:07.0991202Z set-safe-directory: true
2026-07-23T09:29:07.0991592Z allow-unsafe-pr-checkout: false
2026-07-23T09:29:07.0992279Z env:
2026-07-23T09:29:07.0992694Z APP*DIR: /home/***/apps/menugreen
2026-07-23T09:29:07.0993194Z DOPPLER_TOKEN: **_
2026-07-23T09:29:07.0994037Z IMAGE_NAME: _**/menugreensystem
2026-07-23T09:29:07.0994431Z ##[endgroup]
2026-07-23T09:29:07.1788817Z Syncing repository: EXE201-MenuGreen/MenuGreenSystem
2026-07-23T09:29:07.1790990Z ##[group]Getting Git version info
2026-07-23T09:29:07.1791806Z Working directory is '/home/runner/work/MenuGreenSystem/MenuGreenSystem'
2026-07-23T09:29:07.1793001Z [command]/usr/bin/git version
2026-07-23T09:29:07.1793515Z git version 2.54.0
2026-07-23T09:29:07.1796189Z ##[endgroup]
2026-07-23T09:29:07.1807058Z Temporarily overriding HOME='/home/runner/work/\_temp/6f72e396-a77e-41ec-9f32-c1bdd2ede456' before making global git config changes
2026-07-23T09:29:07.1808359Z Adding repository directory to the temporary git global config as a safe directory
2026-07-23T09:29:07.1810317Z [command]/usr/bin/git config --global --add safe.directory /home/runner/work/MenuGreenSystem/MenuGreenSystem
2026-07-23T09:29:07.1838201Z Deleting the contents of '/home/runner/work/MenuGreenSystem/MenuGreenSystem'
2026-07-23T09:29:07.1842368Z ##[group]Initializing the repository
2026-07-23T09:29:07.1845849Z [command]/usr/bin/git init /home/runner/work/MenuGreenSystem/MenuGreenSystem
2026-07-23T09:29:07.2762811Z hint: Using 'master' as the name for the initial branch. This default branch name
2026-07-23T09:29:07.2764031Z hint: will change to "main" in Git 3.0. To configure the initial branch name
2026-07-23T09:29:07.2764872Z hint: to use in all of your new repositories, which will suppress this warning,
2026-07-23T09:29:07.2765557Z hint: call:
2026-07-23T09:29:07.2765980Z hint:
2026-07-23T09:29:07.2766579Z hint: git config --global init.defaultBranch <name>
2026-07-23T09:29:07.2767061Z hint:
2026-07-23T09:29:07.2767649Z hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
2026-07-23T09:29:07.2768396Z hint: 'development'. The just-created branch can be renamed via this command:
2026-07-23T09:29:07.2769040Z hint:
2026-07-23T09:29:07.2769533Z hint: git branch -m <name>
2026-07-23T09:29:07.2770078Z hint:
2026-07-23T09:29:07.2770665Z hint: Disable this message with "git config set advice.defaultBranchName false"
2026-07-23T09:29:07.2771623Z Initialized empty Git repository in /home/runner/work/MenuGreenSystem/MenuGreenSystem/.git/
2026-07-23T09:29:07.2773507Z [command]/usr/bin/git remote add origin https://github.com/EXE201-MenuGreen/MenuGreenSystem
2026-07-23T09:29:07.2802957Z ##[endgroup]
2026-07-23T09:29:07.2803833Z ##[group]Disabling automatic garbage collection
2026-07-23T09:29:07.2806063Z [command]/usr/bin/git config --local gc.auto 0
2026-07-23T09:29:07.2828416Z ##[endgroup]
2026-07-23T09:29:07.2829121Z ##[group]Setting up auth
2026-07-23T09:29:07.2833166Z [command]/usr/bin/git config --local --name-only --get-regexp core\.sshCommand
2026-07-23T09:29:07.2855766Z [command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'core\.sshCommand' && git config --local --unset-all 'core.sshCommand' || :"
2026-07-23T09:29:07.3071269Z [command]/usr/bin/git config --local --name-only --get-regexp http\.https\:\/\/github\.com\/\.extraheader
2026-07-23T09:29:07.3094410Z [command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'http\.https\:\/\/github\.com\/\.extraheader' && git config --local --unset-all 'http.https://github.com/.extraheader' || :"
2026-07-23T09:29:07.3239978Z [command]/usr/bin/git config --local --name-only --get-regexp ^includeIf\.gitdir:
2026-07-23T09:29:07.3262533Z [command]/usr/bin/git submodule foreach --recursive git config --local --show-origin --name-only --get-regexp remote.origin.url
2026-07-23T09:29:07.3407289Z [command]/usr/bin/git config --local http.https://github.com/.extraheader AUTHORIZATION: basic **_
2026-07-23T09:29:07.3432136Z ##[endgroup]
2026-07-23T09:29:07.3432796Z ##[group]Fetching the repository
2026-07-23T09:29:07.3439385Z [command]/usr/bin/git -c protocol.version=2 fetch --no-tags --prune --no-recurse-submodules --depth=1 origin +7a97e2ca866c3f2cabd21e8fcc00ebedafb31373:refs/remotes/origin/develop
2026-07-23T09:29:08.3370460Z From https://github.com/EXE201-MenuGreen/MenuGreenSystem
2026-07-23T09:29:08.3371697Z _ [new ref] 7a97e2ca866c3f2cabd21e8fcc00ebedafb31373 -> origin/develop
2026-07-23T09:29:08.3389260Z ##[endgroup]
2026-07-23T09:29:08.3390045Z ##[group]Determining the checkout info
2026-07-23T09:29:08.3391045Z ##[endgroup]
2026-07-23T09:29:08.3396554Z [command]/usr/bin/git sparse-checkout disable
2026-07-23T09:29:08.3426367Z [command]/usr/bin/git config --local --unset-all extensions.worktreeConfig
2026-07-23T09:29:08.3447030Z ##[group]Checking out the ref
2026-07-23T09:29:08.3450830Z [command]/usr/bin/git checkout --progress --force -B develop refs/remotes/origin/develop
2026-07-23T09:29:08.4864196Z Switched to a new branch 'develop'
2026-07-23T09:29:08.4865338Z branch 'develop' set up to track 'origin/develop'.
2026-07-23T09:29:08.4867789Z ##[endgroup]
2026-07-23T09:29:08.4906168Z [command]/usr/bin/git log -1 --format=%H
2026-07-23T09:29:08.4928818Z 7a97e2ca866c3f2cabd21e8fcc00ebedafb31373
2026-07-23T09:29:08.5089716Z ##[group]Run echo "SHA=7a97e2ca866c3f2cabd21e8fcc00ebedafb31373" >> "$GITHUB_ENV"
2026-07-23T09:29:08.5090553Z [36;1mecho "SHA=7a97e2ca866c3f2cabd21e8fcc00ebedafb31373" >> "$GITHUB*ENV"[0m
2026-07-23T09:29:08.5139033Z shell: /usr/bin/bash -e {0}
2026-07-23T09:29:08.5139549Z env:
2026-07-23T09:29:08.5140080Z APP_DIR: /home/\***/apps/menugreen
2026-07-23T09:29:08.5140700Z DOPPLER_TOKEN: ***
2026-07-23T09:29:08.5141148Z IMAGE*NAME: ***/menugreensystem
2026-07-23T09:29:08.5141610Z ##[endgroup]
2026-07-23T09:29:08.5249104Z ##[group]Run echo "=== Initial disk space ==="
2026-07-23T09:29:08.5249586Z [36;1mecho "=== Initial disk space ==="[0m
2026-07-23T09:29:08.5250031Z [36;1mdf -h[0m
2026-07-23T09:29:08.5279588Z shell: /usr/bin/bash -e {0}
2026-07-23T09:29:08.5280125Z env:
2026-07-23T09:29:08.5280687Z APP_DIR: /home/**_/apps/menugreen
2026-07-23T09:29:08.5281400Z DOPPLER_TOKEN: _**
2026-07-23T09:29:08.5281878Z IMAGE_NAME: **_/menugreensystem
2026-07-23T09:29:08.5282372Z SHA: 7a97e2ca866c3f2cabd21e8fcc00ebedafb31373
2026-07-23T09:29:08.5282886Z ##[endgroup]
2026-07-23T09:29:08.5335151Z === Initial disk space ===
2026-07-23T09:29:08.6419960Z Filesystem Size Used Avail Use% Mounted on
2026-07-23T09:29:08.6421114Z /dev/root 145G 58G 88G 40% /
2026-07-23T09:29:08.6421906Z tmpfs 7.9G 84K 7.9G 1% /dev/shm
2026-07-23T09:29:08.6422617Z tmpfs 3.2G 1020K 3.2G 1% /run
2026-07-23T09:29:08.6423495Z tmpfs 5.0M 0 5.0M 0% /run/lock
2026-07-23T09:29:08.6424689Z /dev/nvme0n1p16 881M 64M 756M 8% /boot
2026-07-23T09:29:08.6425255Z /dev/nvme0n1p15 105M 6.2M 99M 6% /boot/efi
2026-07-23T09:29:08.6425943Z tmpfs 1.6G 12K 1.6G 1% /run/user/1001
2026-07-23T09:29:08.6558480Z ##[group]Run appleboy/scp-action@v0.1.7
2026-07-23T09:29:08.6558997Z with:
2026-07-23T09:29:08.6559671Z host: _**
2026-07-23T09:29:08.6560312Z username: **_
2026-07-23T09:29:08.6566847Z key: _**
2026-07-23T09:29:08.6567678Z source: backend/nginx/nginx.conf,backend/nginx/conf.d/cors-map.conf,backend/scripts/deploy-server.sh,docker-compose.prod.yml
2026-07-23T09:29:08.6568410Z target: /tmp/nginx-deploy
2026-07-23T09:29:08.6568999Z port: 22
2026-07-23T09:29:08.6569590Z timeout: 30s
2026-07-23T09:29:08.6570037Z command_timeout: 10m
2026-07-23T09:29:08.6570570Z use_insecure_cipher: false
2026-07-23T09:29:08.6571014Z rm: false
2026-07-23T09:29:08.6571653Z debug: false
2026-07-23T09:29:08.6572028Z strip_components: 0
2026-07-23T09:29:08.6572619Z overwrite: false
2026-07-23T09:29:08.6573177Z tar_dereference: false
2026-07-23T09:29:08.6573575Z tar_exec: tar
2026-07-23T09:29:08.6574534Z proxy_port: 22
2026-07-23T09:29:08.6575099Z proxy_timeout: 30s
2026-07-23T09:29:08.6575786Z proxy_use_insecure_cipher: false
2026-07-23T09:29:08.6576227Z env:
2026-07-23T09:29:08.6577188Z APP_DIR: /home/**_/apps/menugreen
2026-07-23T09:29:08.6578080Z DOPPLER_TOKEN: _**
2026-07-23T09:29:08.6578662Z IMAGE_NAME: **_/menugreensystem
2026-07-23T09:29:08.6579206Z SHA: 7a97e2ca866c3f2cabd21e8fcc00ebedafb31373
2026-07-23T09:29:08.6579682Z ##[endgroup]
2026-07-23T09:29:08.6698674Z ##[command]/usr/bin/docker run --name bc575deaaf6ba02864a559e0b2bb6e664b3a2_cd98a1 --label 0bc575 --workdir /github/workspace --rm -e "APP_DIR" -e "DOPPLER_TOKEN" -e "IMAGE_NAME" -e "SHA" -e "INPUT_HOST" -e "INPUT_USERNAME" -e "INPUT_KEY" -e "INPUT_SOURCE" -e "INPUT_TARGET" -e "INPUT_PORT" -e "INPUT_PASSWORD" -e "INPUT_TIMEOUT" -e "INPUT_COMMAND_TIMEOUT" -e "INPUT_KEY_PATH" -e "INPUT_PASSPHRASE" -e "INPUT_FINGERPRINT" -e "INPUT_USE_INSECURE_CIPHER" -e "INPUT_RM" -e "INPUT_DEBUG" -e "INPUT_STRIP_COMPONENTS" -e "INPUT_OVERWRITE" -e "INPUT_TAR_DEREFERENCE" -e "INPUT_TAR_TMP_PATH" -e "INPUT_TAR_EXEC" -e "INPUT_PROXY_HOST" -e "INPUT_PROXY_PORT" -e "INPUT_PROXY_USERNAME" -e "INPUT_PROXY_PASSWORD" -e "INPUT_PROXY_PASSPHRASE" -e "INPUT_PROXY_TIMEOUT" -e "INPUT_PROXY_KEY" -e "INPUT_PROXY_KEY_PATH" -e "INPUT_PROXY_FINGERPRINT" -e "INPUT_PROXY_USE_INSECURE_CIPHER" -e "HOME" -e "GITHUB_JOB" -e "GITHUB_REF" -e "GITHUB_SHA" -e "GITHUB_REPOSITORY" -e "GITHUB_REPOSITORY_OWNER" -e "GITHUB_REPOSITORY_OWNER_ID" -e "GITHUB_RUN_ID" -e "GITHUB_RUN_NUMBER" -e "GITHUB_RETENTION_DAYS" -e "GITHUB_RUN_ATTEMPT" -e "GITHUB_ACTOR_ID" -e "GITHUB_ACTOR" -e "GITHUB_WORKFLOW" -e "GITHUB_HEAD_REF" -e "GITHUB_BASE_REF" -e "GITHUB_EVENT_NAME" -e "GITHUB_SERVER_URL" -e "GITHUB_API_URL" -e "GITHUB_GRAPHQL_URL" -e "GITHUB_REF_NAME" -e "GITHUB_REF_PROTECTED" -e "GITHUB_REF_TYPE" -e "GITHUB_WORKFLOW_REF" -e "GITHUB_WORKFLOW_SHA" -e "GITHUB_REPOSITORY_ID" -e "GITHUB_TRIGGERING_ACTOR" -e "GITHUB_WORKSPACE" -e "GITHUB_ACTION" -e "GITHUB_EVENT_PATH" -e "GITHUB_ACTION_REPOSITORY" -e "GITHUB_ACTION_REF" -e "GITHUB_PATH" -e "GITHUB_ENV" -e "GITHUB_STEP_SUMMARY" -e "GITHUB_STATE" -e "GITHUB_OUTPUT" -e "GITHUB_ARTIFACTS" -e "GITHUB_ARTIFACTS_LIST" -e "RUNNER_OS" -e "RUNNER_ARCH" -e "RUNNER_NAME" -e "RUNNER_ENVIRONMENT" -e "RUNNER_TOOL_CACHE" -e "RUNNER_TEMP" -e "RUNNER_WORKSPACE" -e "ACTIONS_RUNTIME_URL" -e "ACTIONS_RUNTIME_TOKEN" -e "ACTIONS_CACHE_URL" -e "ACTIONS_RESULTS_URL" -e "ACTIONS_ORCHESTRATION_ID" -e GITHUB_ACTIONS=true -e CI=true -v "/var/run/docker.sock":"/var/run/docker.sock" -v "/home/runner/work/\_temp":"/github/runner_temp" -v "/home/runner/work/\_temp/\_github_home":"/github/home" -v "/home/runner/work/\_temp/\_github_workflow":"/github/workflow" -v "/home/runner/work/\_temp/\_runner_file_commands":"/github/file_commands" -v "/home/runner/work/MenuGreenSystem/MenuGreenSystem":"/github/workspace" 0bc575:deaaf6ba02864a559e0b2bb6e664b3a2
2026-07-23T09:29:09.3237560Z drone-scp version: v1.6.14
2026-07-23T09:29:09.3238282Z tar all files into /tmp/dPhSniUDMZ.tar.gz
2026-07-23T09:29:12.1543013Z remote server os type is unix
2026-07-23T09:29:12.1544404Z scp file to server.
2026-07-23T09:29:17.6950902Z create folder /tmp/nginx-deploy
2026-07-23T09:29:19.9416148Z untar file dPhSniUDMZ.tar.gz
2026-07-23T09:29:22.1877046Z remove file dPhSniUDMZ.tar.gz
2026-07-23T09:29:24.4325602Z ===================================================
2026-07-23T09:29:24.4326757Z ✅ Successfully executed transfer data to all host
2026-07-23T09:29:24.4327337Z ===================================================
2026-07-23T09:29:24.6440603Z ##[group]Run appleboy/ssh-action@v1.1.0
2026-07-23T09:29:24.6441099Z with:
2026-07-23T09:29:24.6441735Z host: _**
2026-07-23T09:29:24.6442099Z username: **_
2026-07-23T09:29:24.6447173Z key: _\*\*
2026-07-23T09:29:24.6447577Z port: 22
2026-07-23T09:29:24.6447972Z envs: DOPPLER_TOKEN,APP_DIR,IMAGE_NAME,SHA
2026-07-23T09:29:24.6448395Z debug: true
2026-07-23T09:29:24.6449006Z script: set -e
chmod +x /tmp/nginx-deploy/backend/scripts/deploy-server.sh
/tmp/nginx-deploy/backend/scripts/deploy-server.sh

2026-07-23T09:29:24.6449775Z protocol: tcp
2026-07-23T09:29:24.6450105Z timeout: 30s
2026-07-23T09:29:24.6450501Z command*timeout: 10m
2026-07-23T09:29:24.6451061Z proxy_port: 22
2026-07-23T09:29:24.6451401Z proxy_timeout: 30s
2026-07-23T09:29:24.6451888Z env:
2026-07-23T09:29:24.6452269Z APP_DIR: /home/\*\**/apps/menugreen
2026-07-23T09:29:24.6452824Z DOPPLER*TOKEN: ***
2026-07-23T09:29:24.6453225Z IMAGE_NAME: **_/menugreensystem
2026-07-23T09:29:24.6454031Z SHA: 7a97e2ca866c3f2cabd21e8fcc00ebedafb31373
2026-07-23T09:29:24.6454508Z ##[endgroup]
2026-07-23T09:29:24.6506445Z ##[start-action display=Set GitHub Path;id=__appleboy_ssh-action.__run]
2026-07-23T09:29:24.6529084Z ##[group]Run echo "$GITHUB_ACTION_PATH" >> $GITHUB_PATH
2026-07-23T09:29:24.6529576Z [36;1mecho "$GITHUB_ACTION_PATH" >> $GITHUB_PATH[0m
2026-07-23T09:29:24.6564393Z shell: /usr/bin/bash --noprofile --norc -e -o pipefail {0}
2026-07-23T09:29:24.6564819Z env:
2026-07-23T09:29:24.6565323Z APP_DIR: /home/_**/apps/menugreen
2026-07-23T09:29:24.6565952Z DOPPLER_TOKEN: **_
2026-07-23T09:29:24.6566356Z IMAGE_NAME: _**/menugreensystem
2026-07-23T09:29:24.6566775Z SHA: 7a97e2ca866c3f2cabd21e8fcc00ebedafb31373
2026-07-23T09:29:24.6567327Z GITHUB_ACTION_PATH: /home/runner/work/\_actions/appleboy/ssh-action/v1.1.0
2026-07-23T09:29:24.6567784Z ##[endgroup]
2026-07-23T09:29:24.6626831Z ##[end-action id=__appleboy_ssh-action.__run;outcome=success;conclusion=success;duration_ms=11]
2026-07-23T09:29:24.6635064Z ##[start-action display=Run entrypoint.sh;id=__appleboy_ssh-action.__run_2]
2026-07-23T09:29:24.6650638Z ##[group]Run entrypoint.sh
2026-07-23T09:29:24.6651036Z [36;1mentrypoint.sh[0m
2026-07-23T09:29:24.6677509Z shell: /usr/bin/bash --noprofile --norc -e -o pipefail {0}
2026-07-23T09:29:24.6677977Z env:
2026-07-23T09:29:24.6678427Z APP_DIR: /home/**_/apps/menugreen
2026-07-23T09:29:24.6678917Z DOPPLER_TOKEN: _**
2026-07-23T09:29:24.6679453Z IMAGE_NAME: **_/menugreensystem
2026-07-23T09:29:24.6679851Z SHA: 7a97e2ca866c3f2cabd21e8fcc00ebedafb31373
2026-07-23T09:29:24.6680378Z GITHUB_ACTION_PATH: /home/runner/work/\_actions/appleboy/ssh-action/v1.1.0
2026-07-23T09:29:24.6680876Z INPUT_HOST: _**
2026-07-23T09:29:24.6681236Z INPUT_PORT: 22
2026-07-23T09:29:24.6681614Z INPUT_PROTOCOL: tcp
2026-07-23T09:29:24.6682003Z INPUT_USERNAME: **_
2026-07-23T09:29:24.6682338Z INPUT_PASSWORD:
2026-07-23T09:29:24.6682710Z INPUT_PASSPHRASE:
2026-07-23T09:29:24.6687668Z INPUT_KEY: _\*\*
2026-07-23T09:29:24.6688083Z INPUT_KEY_PATH:
2026-07-23T09:29:24.6688474Z INPUT_FINGERPRINT:
2026-07-23T09:29:24.6688871Z INPUT_PROXY_HOST:
2026-07-23T09:29:24.6689250Z INPUT_PROXY_PORT: 22
2026-07-23T09:29:24.6689643Z INPUT_PROXY_USERNAME:
2026-07-23T09:29:24.6690054Z INPUT_PROXY_PASSWORD:
2026-07-23T09:29:24.6690426Z INPUT_PROXY_PASSPHRASE:
2026-07-23T09:29:24.6690849Z INPUT_PROXY_KEY:
2026-07-23T09:29:24.6691224Z INPUT_PROXY_KEY_PATH:
2026-07-23T09:29:24.6691641Z INPUT_PROXY_FINGERPRINT:
2026-07-23T09:29:24.6692088Z INPUT_TIMEOUT: 30s
2026-07-23T09:29:24.6692465Z INPUT_PROXY_TIMEOUT: 30s
2026-07-23T09:29:24.6692900Z INPUT_COMMAND_TIMEOUT: 10m
2026-07-23T09:29:24.6693802Z INPUT_SCRIPT: set -e
chmod +x /tmp/nginx-deploy/backend/scripts/deploy-server.sh
/tmp/nginx-deploy/backend/scripts/deploy-server.sh

2026-07-23T09:29:24.6694532Z INPUT*SCRIPT_STOP:
2026-07-23T09:29:24.6694955Z INPUT_ENVS: DOPPLER_TOKEN,APP_DIR,IMAGE_NAME,SHA
2026-07-23T09:29:24.6695677Z INPUT_ENVS_FORMAT:
2026-07-23T09:29:24.6696060Z INPUT_DEBUG: true
2026-07-23T09:29:24.6696475Z INPUT_ALL_ENVS:
2026-07-23T09:29:24.6696813Z INPUT_REQUEST_PTY:
2026-07-23T09:29:24.6697247Z INPUT_USE_INSECURE_CIPHER:
2026-07-23T09:29:24.6697689Z INPUT_CIPHER:
2026-07-23T09:29:24.6698038Z INPUT_PROXY_USE_INSECURE_CIPHER:
2026-07-23T09:29:24.6698484Z INPUT_PROXY_CIPHER:
2026-07-23T09:29:24.6698885Z INPUT_SYNC:
2026-07-23T09:29:24.6699218Z ##[endgroup]
2026-07-23T09:29:24.6785198Z Will download drone-ssh-1.7.7-linux-amd64 from https://github.com/appleboy/drone-ssh/releases/download/v1.7.7
2026-07-23T09:29:25.0885512Z ======= CLI Version =======
2026-07-23T09:29:25.0908950Z Drone SSH version 1.7.7
2026-07-23T09:29:25.0910938Z ===========================
2026-07-23T09:29:25.0938407Z ======CMD======
2026-07-23T09:29:25.0938889Z set -e
2026-07-23T09:29:25.0939353Z chmod +x /tmp/nginx-deploy/backend/scripts/deploy-server.sh
2026-07-23T09:29:25.0939841Z /tmp/nginx-deploy/backend/scripts/deploy-server.sh
2026-07-23T09:29:25.0940168Z
2026-07-23T09:29:25.0940335Z ======END======
2026-07-23T09:29:25.0940684Z ======ENV======
2026-07-23T09:29:25.0941269Z export DOPPLER_TOKEN='\*\**'
2026-07-23T09:29:25.0941717Z export APP*DIR='/home/***/apps/menugreen'
2026-07-23T09:29:25.0942208Z export IMAGE_NAME='**_/menugreensystem'
2026-07-23T09:29:25.0942639Z export SHA='7a97e2ca866c3f2cabd21e8fcc00ebedafb31373'
2026-07-23T09:29:25.0943072Z ======END======
2026-07-23T09:29:27.3332257Z out: === [0a] Ensure self-signed cert exists ===
2026-07-23T09:29:27.3516804Z err: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:29:27.5558161Z err: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:29:27.5712440Z err: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:29:27.5772189Z out: ✓ Generated self-signed cert
2026-07-23T09:29:27.5786211Z out: === [0/10] Apply nginx config from git ===
2026-07-23T09:29:27.5804360Z out: Found nginx.conf at: /tmp/nginx-deploy/backend/nginx/nginx.conf
2026-07-23T09:29:27.5804994Z out: Found cors-map.conf at: /tmp/nginx-deploy/backend/nginx/conf.d/cors-map.conf
2026-07-23T09:29:27.5927091Z err: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:29:27.6106154Z err: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:29:27.6268417Z err: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:29:27.6439213Z err: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:29:27.6617363Z err: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:29:27.7667086Z err: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:29:27.7667966Z err: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:29:27.7668559Z out: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:29:27.7669099Z out: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
2026-07-23T09:29:27.7669657Z out: nginx: configuration file /etc/nginx/nginx.conf test is successful
2026-07-23T09:29:27.7670416Z out: ✓ Nginx config applied and reloaded
2026-07-23T09:29:27.7670833Z out: === Cleanup disk space - Before ===
2026-07-23T09:29:27.8534436Z out: Deleted Images:
2026-07-23T09:29:27.8535664Z out: untagged: _**/menugreensystem:main
2026-07-23T09:29:27.8536159Z out: untagged: menugreen_api:latest
2026-07-23T09:29:27.8536663Z out: deleted: sha256:2d18447df21556f4d453d284878f18b717a449f2c9f3836d5a94f5981a015d5d
2026-07-23T09:29:27.8621341Z out: Total reclaimed space: 33.26MB
2026-07-23T09:29:27.8658163Z out: === Disk space after cleanup ===
2026-07-23T09:29:27.8678487Z out: Filesystem Size Used Avail Use% Mounted on
2026-07-23T09:29:27.8679170Z out: /dev/root 58G 7.4G 51G 13% /
2026-07-23T09:29:27.8679705Z out: tmpfs 956M 0 956M 0% /dev/shm
2026-07-23T09:29:27.8680640Z out: tmpfs 383M 1.2M 381M 1% /run
2026-07-23T09:29:27.8681146Z out: tmpfs 5.0M 0 5.0M 0% /run/lock
2026-07-23T09:29:27.8682074Z out: efivarfs 128K 3.1K 120K 3% /sys/firmware/efi/efivars
2026-07-23T09:29:27.8682662Z out: /dev/nvme0n1p15 105M 6.1M 99M 6% /boot/efi
2026-07-23T09:29:27.8683168Z out: tmpfs 192M 4.0K 192M 1% /run/user/1000
2026-07-23T09:29:27.8683837Z out: === Locate SCP'd docker-compose.prod.yml ===
2026-07-23T09:29:27.8684421Z out: Found docker-compose.prod.yml at: /tmp/nginx-deploy/docker-compose.prod.yml
2026-07-23T09:29:27.8702821Z out: === docker-compose.prod.yml installed ===
2026-07-23T09:29:27.8932206Z out: === Install Doppler CLI ===
2026-07-23T09:29:28.8716015Z out: === Download secrets from Doppler ===
2026-07-23T09:29:29.5017961Z out: === Materialize Firebase credentials JSON ===
2026-07-23T09:29:29.8814126Z err: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:29:29.8965299Z err: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:29:29.9124883Z err: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:29:29.9292815Z err: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:29:29.9456246Z err: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:29:29.9864183Z err: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:29:29.9938631Z out: ✓ Firebase credentials materialized (root:root, mode 600, valid JSON, real-PEM private_key)
2026-07-23T09:29:30.2035345Z out: === .env file created ===
2026-07-23T09:29:30.2192876Z out: === Starting database backup ===
2026-07-23T09:29:30.5613146Z out: Backup saved to: /tmp/menugreen_backup_20260723_092930.sql
2026-07-23T09:29:30.5658290Z out: === Save previous image locally for rollback ===
2026-07-23T09:29:30.5968425Z err: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:29:30.6181893Z err: Error response from daemon: No such image: menugreen_api:latest
2026-07-23T09:29:30.6210478Z out: ! Could not tag previous image (non-fatal)
2026-07-23T09:29:30.6211651Z out: ✓ Saved rollback image as menugreen_api:rollback-local-1784798970
2026-07-23T09:29:30.6212194Z out: === Pull latest image ===
2026-07-23T09:29:34.7262472Z out: acbb93984b2d: Download complete
2026-07-23T09:29:34.7263460Z out: acbb93984b2d: Pull complete
2026-07-23T09:29:34.7264189Z out: Digest: sha256:2d18447df21556f4d453d284878f18b717a449f2c9f3836d5a94f5981a015d5d
2026-07-23T09:29:34.7265042Z out: Status: Downloaded newer image for **_/menugreensystem:main
2026-07-23T09:29:34.7265520Z out: docker.io/_**/menugreensystem:main
2026-07-23T09:29:34.7266006Z out: === Tag image for local use ===
2026-07-23T09:29:34.7368405Z err: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:29:34.7876137Z out: === Stop and remove all existing containers ===
2026-07-23T09:29:35.1693237Z out: === Start API container ===
2026-07-23T09:29:35.2719888Z err: Image docker.io/**_/menugreensystem:latest Pulling
2026-07-23T09:29:39.3210707Z err: e90c8f7ed849 Pulling fs layer 0B
2026-07-23T09:29:39.3211969Z err: 7c3ef23a5ab2 Pulling fs layer 0B
2026-07-23T09:29:39.3212424Z err: 4f4fb700ef54 Pulling fs layer 0B
2026-07-23T09:29:39.4142986Z err: 4f4fb700ef54 Already exists 0B
2026-07-23T09:29:41.5134135Z err: e90c8f7ed849 Downloading 1.049MB
2026-07-23T09:29:41.6135573Z err: e90c8f7ed849 Downloading 1.049MB
2026-07-23T09:29:41.7133316Z err: e90c8f7ed849 Downloading 2.097MB
2026-07-23T09:29:41.7134620Z err: 7c3ef23a5ab2 Downloading 1.049MB
2026-07-23T09:29:41.8125586Z err: e90c8f7ed849 Downloading 3.146MB
2026-07-23T09:29:41.8126205Z err: 7c3ef23a5ab2 Downloading 1.049MB
2026-07-23T09:29:41.9150118Z err: e90c8f7ed849 Downloading 4.194MB
2026-07-23T09:29:41.9150898Z err: 7c3ef23a5ab2 Downloading 2.27MB
2026-07-23T09:29:42.0132134Z err: e90c8f7ed849 Download complete 0B
2026-07-23T09:29:42.0148942Z err: 7c3ef23a5ab2 Download complete 0B
2026-07-23T09:29:42.0175227Z err: 7c3ef23a5ab2 Extracting 1B
2026-07-23T09:29:42.1147945Z err: 4f4fb700ef54 Pull complete 0B
2026-07-23T09:29:42.1158833Z err: e90c8f7ed849 Extracting 1B
2026-07-23T09:29:42.1175944Z err: 7c3ef23a5ab2 Pull complete 0B
2026-07-23T09:29:42.2142214Z err: e90c8f7ed849 Extracting 1B
2026-07-23T09:29:42.2539706Z err: e90c8f7ed849 Pull complete 0B
2026-07-23T09:29:42.2594527Z err: Image docker.io/_**/menugreensystem:latest Pulled
2026-07-23T09:29:42.3011424Z err: Container menugreen_api Creating
2026-07-23T09:29:42.4132368Z err: Container menugreen_api Created
2026-07-23T09:29:42.4194009Z err: Container menugreen_api Starting
2026-07-23T09:29:42.6468330Z err: Container menugreen_api Started
2026-07-23T09:29:42.6509185Z out: === Waiting for container to be ready ===
2026-07-23T09:29:42.6869861Z out: Container is running!
2026-07-23T09:29:42.6870493Z out: === Waiting for app startup and auto-migration (max 45 seconds) ===
2026-07-23T09:29:57.6903980Z out: App should have auto-migrated on startup.
2026-07-23T09:29:57.6904845Z out: Checking database tables...
2026-07-23T09:29:57.7171349Z out: === Waiting for health check (max 30 attempts) ===
2026-07-23T09:29:57.7309033Z out: Waiting for health check... (1/30)
2026-07-23T09:29:59.7446010Z out: Waiting for health check... (2/30)
2026-07-23T09:30:01.8156272Z out: Waiting for health check... (3/30)
2026-07-23T09:30:03.8997335Z out: Waiting for health check... (4/30)
2026-07-23T09:30:05.9508490Z out: Waiting for health check... (5/30)
2026-07-23T09:30:07.9708734Z out: Waiting for health check... (6/30)
2026-07-23T09:30:09.9839480Z out: Waiting for health check... (7/30)
2026-07-23T09:30:11.9937981Z out: Waiting for health check... (8/30)
2026-07-23T09:30:14.0046015Z out: Waiting for health check... (9/30)
2026-07-23T09:30:16.0163269Z out: Waiting for health check... (10/30)
2026-07-23T09:30:18.0309886Z out: Waiting for health check... (11/30)
2026-07-23T09:30:20.0427286Z out: Waiting for health check... (12/30)
2026-07-23T09:30:22.0527367Z out: Waiting for health check... (13/30)
2026-07-23T09:30:24.0628599Z out: Waiting for health check... (14/30)
2026-07-23T09:30:26.0722599Z out: Waiting for health check... (15/30)
2026-07-23T09:30:28.0814623Z out: Waiting for health check... (16/30)
2026-07-23T09:30:30.0908213Z out: Waiting for health check... (17/30)
2026-07-23T09:30:32.1024798Z out: Waiting for health check... (18/30)
2026-07-23T09:30:34.1167762Z out: Waiting for health check... (19/30)
2026-07-23T09:30:36.1268885Z out: Waiting for health check... (20/30)
2026-07-23T09:30:38.1369520Z out: Waiting for health check... (21/30)
2026-07-23T09:30:40.1481057Z out: Waiting for health check... (22/30)
2026-07-23T09:30:42.1640429Z out: Waiting for health check... (23/30)
2026-07-23T09:30:44.1757901Z out: Waiting for health check... (24/30)
2026-07-23T09:30:46.1857427Z out: Waiting for health check... (25/30)
2026-07-23T09:30:48.1949058Z out: Waiting for health check... (26/30)
2026-07-23T09:30:50.2044566Z out: Waiting for health check... (27/30)
2026-07-23T09:30:52.2140221Z out: Waiting for health check... (28/30)
2026-07-23T09:30:54.2242127Z out: Waiting for health check... (29/30)
2026-07-23T09:30:56.2334232Z out: Waiting for health check... (30/30)
2026-07-23T09:30:58.2356288Z out: >>> Health check failed after 30 attempts, initiating rollback...
2026-07-23T09:30:58.2358304Z out: >>> Initiating rollback...
2026-07-23T09:30:58.2358849Z out: >>> Logging failed container...
2026-07-23T09:30:58.3176362Z out: menugreen_api | Entity 'User' has a global query filter defined and is the required end of a relationship with the entity 'UserAllergy'. This may lead to unexpected results when the required entity is filtered out. Either configure the navigation as optional, or define matching query filters for both entities in the navigation. See https://go.microsoft.com/fwlink/?linkid=2131316 for more information.
2026-07-23T09:30:58.3178795Z out: menugreen_api | warn: Microsoft.EntityFrameworkCore.Model.Validation[10622]
2026-07-23T09:30:58.3180120Z out: menugreen_api | Entity 'User' has a global query filter defined and is the required end of a relationship with the entity 'UserCardInteraction'. This may lead to unexpected results when the required entity is filtered out. Either configure the navigation as optional, or define matching query filters for both entities in the navigation. See https://go.microsoft.com/fwlink/?linkid=2131316 for more information.
2026-07-23T09:30:58.3181341Z out: menugreen_api | warn: Microsoft.EntityFrameworkCore.Model.Validation[10622]
2026-07-23T09:30:58.3182541Z out: menugreen_api | Entity 'User' has a global query filter defined and is the required end of a relationship with the entity 'UserPremiumProgram'. This may lead to unexpected results when the required entity is filtered out. Either configure the navigation as optional, or define matching query filters for both entities in the navigation. See https://go.microsoft.com/fwlink/?linkid=2131316 for more information.
2026-07-23T09:30:58.3184049Z out: menugreen_api | warn: Microsoft.EntityFrameworkCore.Model.Validation[10622]
2026-07-23T09:30:58.3185295Z out: menugreen_api | Entity 'User' has a global query filter defined and is the required end of a relationship with the entity 'UserSubscription'. This may lead to unexpected results when the required entity is filtered out. Either configure the navigation as optional, or define matching query filters for both entities in the navigation. See https://go.microsoft.com/fwlink/?linkid=2131316 for more information.
2026-07-23T09:30:58.3186453Z out: menugreen_api | warn: Microsoft.EntityFrameworkCore.Model.Validation[10622]
2026-07-23T09:30:58.3187659Z out: menugreen_api | Entity 'User' has a global query filter defined and is the required end of a relationship with the entity 'UserSubstitutionPreference'. This may lead to unexpected results when the required entity is filtered out. Either configure the navigation as optional, or define matching query filters for both entities in the navigation. See https://go.microsoft.com/fwlink/?linkid=2131316 for more information.
2026-07-23T09:30:58.3188847Z out: menugreen_api | warn: Microsoft.EntityFrameworkCore.Model.Validation[10622]
2026-07-23T09:30:58.3189990Z out: menugreen_api | Entity 'User' has a global query filter defined and is the required end of a relationship with the entity 'WeightLog'. This may lead to unexpected results when the required entity is filtered out. Either configure the navigation as optional, or define matching query filters for both entities in the navigation. See https://go.microsoft.com/fwlink/?linkid=2131316 for more information.
2026-07-23T09:30:58.3191134Z out: menugreen_api | info: Microsoft.EntityFrameworkCore.Database.Command[20101]
2026-07-23T09:30:58.3191657Z out: menugreen_api | Executed DbCommand (19ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
2026-07-23T09:30:58.3192135Z out: menugreen_api | SELECT "MigrationId", "ProductVersion"
2026-07-23T09:30:58.3192517Z out: menugreen_api | FROM "**EFMigrationsHistory"
2026-07-23T09:30:58.3192865Z out: menugreen*api | ORDER BY "MigrationId";
2026-07-23T09:30:58.3193259Z out: menugreen_api | info: Microsoft.EntityFrameworkCore.Database.Command[20101]
2026-07-23T09:30:58.3193916Z out: menugreen_api | Executed DbCommand (3ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
2026-07-23T09:30:58.3194387Z out: menugreen_api | SELECT "MigrationId", "ProductVersion"
2026-07-23T09:30:58.3194749Z out: menugreen_api | FROM "**EFMigrationsHistory"
2026-07-23T09:30:58.3195089Z out: menugreen_api | ORDER BY "MigrationId";
2026-07-23T09:30:58.3195394Z out: menugreen_api | info: Program[0]
2026-07-23T09:30:58.3196472Z out: menugreen_api | [MIGRATION] Applied (8): [20260629084940_InitialCreate, 20260702122304_AddUsersTable, 20260711083535_AddRegionToFood, 20260716160000_AddGymerSubscriptionPlan, 20260717110000_AddPremiumProgramMeasurementsAndRewards, 20260717110500_AddHealthTargetWeight, 20260721103000_AddCasualSubscriptionPlan, 20260722055258_TriggerRebuild_20260722]
2026-07-23T09:30:58.3197472Z out: menugreen_api | info: Program[0]
2026-07-23T09:30:58.3197790Z out: menugreen_api | [MIGRATION] Pending (0): []
2026-07-23T09:30:58.3198112Z out: menugreen_api | warn: Program[0]
2026-07-23T09:30:58.3199503Z out: menugreen_api | [MIGRATION] DRIFT DETECTED: 8 migration(s) are recorded in **EFMigrationsHistory but are NOT present in the running DLL: [20260629084940_InitialCreate, 20260702122304_AddUsersTable, 20260711083535_AddRegionToFood, 20260716160000_AddGymerSubscriptionPlan, 20260717110000_AddPremiumProgramMeasurementsAndRewards, 20260717110500_AddHealthTargetWeight, 20260721103000_AddCasualSubscriptionPlan, 20260722055258_TriggerRebuild_20260722]. Auto-apply will refuse to start. Rollback the image or remove the stale rows manually.
2026-07-23T09:30:58.3201335Z out: menugreen_api | info: Program[0]
2026-07-23T09:30:58.3201738Z out: menugreen_api | [MIGRATION] Applying database migrations...
2026-07-23T09:30:58.3202232Z out: menugreen_api | info: Microsoft.EntityFrameworkCore.Database.Command[20101]
2026-07-23T09:30:58.3202892Z out: menugreen_api | Executed DbCommand (2ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
2026-07-23T09:30:58.3203360Z out: menugreen_api | SELECT "MigrationId", "ProductVersion"
2026-07-23T09:30:58.3203888Z out: menugreen_api | FROM "**EFMigrationsHistory"
2026-07-23T09:30:58.3204231Z out: menugreen_api | ORDER BY "MigrationId";
2026-07-23T09:30:58.3204536Z out: menugreen_api | crit: Program[0]
2026-07-23T09:30:58.3205034Z out: menugreen_api | FATAL: Failed to apply database migrations. Application will NOT start to avoid serving requests with mismatched schema.
2026-07-23T09:30:58.3206558Z out: menugreen_api | System.InvalidOperationException: An error was generated for warning 'Microsoft.EntityFrameworkCore.Migrations.PendingModelChangesWarning': The model for context 'ApplicationDbContext' has pending changes. Add a new migration before updating the database. This exception can be suppressed or logged by passing event ID 'RelationalEventId.PendingModelChangesWarning' to the 'ConfigureWarnings' method in 'DbContext.OnConfiguring' or 'AddDbContext'.
2026-07-23T09:30:58.3208137Z out: menugreen_api | at Microsoft.EntityFrameworkCore.Diagnostics.EventDefinition`1.Log[TLoggerCategory](IDiagnosticsLogger`1 logger, TParam arg)
2026-07-23T09:30:58.3209044Z out: menugreen_api | at Microsoft.EntityFrameworkCore.Diagnostics.RelationalLoggerExtensions.PendingModelChangesWarning(IDiagnosticsLogger`1 diagnostics, Type contextType)
2026-07-23T09:30:58.3209902Z out: menugreen_api  |          at Microsoft.EntityFrameworkCore.Migrations.Internal.Migrator.Migrate(String targetMigration)
2026-07-23T09:30:58.3210628Z out: menugreen_api  |          at Npgsql.EntityFrameworkCore.PostgreSQL.Migrations.Internal.NpgsqlMigrator.Migrate(String targetMigration)
2026-07-23T09:30:58.3211397Z out: menugreen_api  |          at Microsoft.EntityFrameworkCore.RelationalDatabaseFacadeExtensions.Migrate(DatabaseFacade databaseFacade)
2026-07-23T09:30:58.3212090Z out: menugreen_api  |          at Program.<Main>$(String[] args) in /src/backend/MenuGreen.API/Program.cs:line 510
2026-07-23T09:30:58.3213573Z out: menugreen_api  | Unhandled exception. System.InvalidOperationException: An error was generated for warning 'Microsoft.EntityFrameworkCore.Migrations.PendingModelChangesWarning': The model for context 'ApplicationDbContext' has pending changes. Add a new migration before updating the database. This exception can be suppressed or logged by passing event ID 'RelationalEventId.PendingModelChangesWarning' to the 'ConfigureWarnings' method in 'DbContext.OnConfiguring' or 'AddDbContext'.
2026-07-23T09:30:58.3215348Z out: menugreen_api  |    at Microsoft.EntityFrameworkCore.Diagnostics.EventDefinition`1.Log[TLoggerCategory](IDiagnosticsLogger`1 logger, TParam arg)
2026-07-23T09:30:58.3216337Z out: menugreen_api  |    at Microsoft.EntityFrameworkCore.Diagnostics.RelationalLoggerExtensions.PendingModelChangesWarning(IDiagnosticsLogger`1 diagnostics, Type contextType)
2026-07-23T09:30:58.3217175Z out: menugreen_api | at Microsoft.EntityFrameworkCore.Migrations.Internal.Migrator.Migrate(String targetMigration)
2026-07-23T09:30:58.3217908Z out: menugreen_api | at Npgsql.EntityFrameworkCore.PostgreSQL.Migrations.Internal.NpgsqlMigrator.Migrate(String targetMigration)
2026-07-23T09:30:58.3218677Z out: menugreen_api | at Microsoft.EntityFrameworkCore.RelationalDatabaseFacadeExtensions.Migrate(DatabaseFacade databaseFacade)
2026-07-23T09:30:58.3219332Z out: menugreen_api | at Program.<Main>$(String[] args) in /src/backend/MenuGreen.API/Program.cs:line 510
2026-07-23T09:30:58.3219813Z out: >>> Stopping current containers...
2026-07-23T09:30:58.4657366Z err: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:30:58.5862373Z out: >>> No local rollback tag found, trying ***/menugreensystem:previous...
2026-07-23T09:30:59.8532899Z out: >>> No \_\*\*/menugreensystem:previous, trying \*\*\*/menugreensystem:main-<oldsha> from Hub...
2026-07-23T09:30:59.8646838Z err: sudo: unable to resolve host menugreen-api: Name or service not known
2026-07-23T09:30:59.9918453Z out: >>> FATAL: No rollback image available (local, :previous, or :main-<sha>)
2026-07-23T09:30:59.9919853Z out: >>> Manual recovery required. Service is DOWN.
2026-07-23T09:30:59.9920340Z out: >>> Container state preserved for debugging.
2026-07-23T09:30:59.9921398Z 2026/07/23 09:30:59 Process exited with status 1
2026-07-23T09:30:59.9944799Z ##[error]Process completed with exit code 1.
2026-07-23T09:30:59.9951074Z ##[end-action id=__appleboy_ssh-action.__run_2;outcome=failure;conclusion=failure;duration_ms=95331]
2026-07-23T09:31:00.0042196Z Post job cleanup.
2026-07-23T09:31:00.0706387Z [command]/usr/bin/git version
2026-07-23T09:31:00.0731957Z git version 2.54.0
2026-07-23T09:31:00.0756912Z Temporarily overriding HOME='/home/runner/work/\_temp/89084f10-1794-4bc9-ae9f-c7daaf1569fa' before making global git config changes
2026-07-23T09:31:00.0757863Z Adding repository directory to the temporary git global config as a safe directory
2026-07-23T09:31:00.0760976Z [command]/usr/bin/git config --global --add safe.directory /home/runner/work/MenuGreenSystem/MenuGreenSystem
2026-07-23T09:31:00.0790713Z [command]/usr/bin/git config --local --name-only --get-regexp core\.sshCommand
2026-07-23T09:31:00.0816978Z [command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'core\.sshCommand' && git config --local --unset-all 'core.sshCommand' || :"
2026-07-23T09:31:00.0984595Z [command]/usr/bin/git config --local --name-only --get-regexp http\.https\:\/\/github\.com\/\.extraheader
2026-07-23T09:31:00.1001256Z http.https://github.com/.extraheader
2026-07-23T09:31:00.1008721Z [command]/usr/bin/git config --local --unset-all http.https://github.com/.extraheader
2026-07-23T09:31:00.1036309Z [command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'http\.https\:\/\/github\.com\/\.extraheader' && git config --local --unset-all 'http.https://github.com/.extraheader' || :"
2026-07-23T09:31:00.1205830Z [command]/usr/bin/git config --local --name-only --get-regexp ^includeIf\.gitdir:
2026-07-23T09:31:00.1230124Z [command]/usr/bin/git submodule foreach --recursive git config --local --show-origin --name-only --get-regexp remote.origin.url
2026-07-23T09:31:00.1540394Z Cleaning up orphan processes
Beta
0 / 0
used queries
