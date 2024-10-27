#!/bin/bash

# webdevteam D5A7D232A215A50940921C542C14290A
read -p "Steam user (webdevteam):" STEAMUSER
read -p "Steam password:" STEAMPASS
read -p "Steam token:" TOKEN
read -p "Steam port (27015):" GPORT
read -p "Steam tv_port (27016):" TPORT
read -p "Container name (TestServer):" CONTNAME
read -p "Server name (TestServer):" SERVERNAME
read -p "Username folderpath (izocel):" USERFOLDER

CONTNAME="CS2-$CONTNAME"
HOMESPATH="/volume1/homes"
VOLPATH="$HOMESPATH/$USERFOLDER/docker/$CONTNAME"
RCONPASS=$(head -c 16 /dev/random | md5sum | cut -f 1 -d\ )
SRVRPASS=$(head -c 16 /dev/random | md5sum | cut -f 1 -d\ )

REGION=0
MAXPLAYER=12
MAP="de_nuke"
TYPE=1
MODE=2
FLAG=0
SKMD=3
WCOL=0
WMAP=0
ARGS=""

echo ""
echo "Container name: $CONTNAME"
echo "Volume path: $VOLPATH"
echo "Server name: $SERVERNAME"
echo "Game port: $GPORT"
echo "Tv-Game port: $TPORT"
echo "Game Token: $TOKEN"
echo "RCON-PASS: $RCONPASS"
echo "SERVER-PASS: $SRVRPASS"
echo ""


read -p "Confirm configs (y/n)?" CONTINUE
if [ "$CONTINUE" != "y" ]; then
    echo "Exiting..."
    exit
fi

mkdir -p "$VOLPATH/user" && chmod 777 "$VOLPATH/user"
mkdir -p "$VOLPATH/steam" && chmod 777 "$VOLPATH/steam"
docker volume create --name $CONTNAME-USER --opt type=none --opt device="$VOLPATH/user" --opt o=bind
docker volume create --name $CONTNAME-STEAM --opt type=none --opt device="$VOLPATH/steam" --opt o=bind

read -p "Confirm volumes OK (y/n)?" CONTINUE
if [ "$CONTINUE" != "y" ]; then
    echo "Exiting..."
    exit
fi

echo ""
docker run -it -d --name="SteamCMD" -v "SteamCMD:/home/steam/Steam" cm2network/steamcmd
docker exec -it "SteamCMD" sh -c "chmod 755 /home/steam/steamcmd/steamcmd.sh && /home/steam/steamcmd/steamcmd.sh +login $STEAMUSER $STEAMPASS +quit"
docker stop SteamCMD && docker rm SteamCMD

echo ""
read -p "Confirm steam cmd login OK (y/n)?" CONTINUE
if [ "$CONTINUE" != "y" ]; then
    echo "Exiting..."
    exit
fi

echo ""
echo "Creating cs2 server container..."
docker run -it -d --net=bridge -p $GPORT:$GPORT/tcp -p $GPORT:$GPORT/udp -p $TPORT:$TPORT/tcp -p $TPORT:$TPORT/udp \
    --name="$CONTNAME" \
    -v "$CONTNAME-USER:/usr/" \
    -v "$CONTNAME-STEAM:/home/steam/" \
    -v "SteamCMD:/home/steam/Steam" \
    -e STEAMUSER=$STEAMUSER \
    -e CS2_RCONPW=$RCONPASS \
    -e CS2_PW=$SRVRPASS \
    -e CS2_LAN="0" \
    -e CS2_FPSMAX=128 \
    -e CS2_TICKRATE=512 \
    -e CS2_REGION=$REGION \
    -e CS2_PORT=$GPORT \
    -e CS2_TV_PORT=$TPORT \
    -e CS2_GAMETYPE=$TYPE \
    -e CS2_GAMEMODE=$MODE \
    -e CS2_MAXPLAYERS=$MAXPLAYER \
    -e CS2_SERVERNAME="$SERVERNAME" \
    -e CS2_MAPGROUP="mg_active" \
    -e CS2_STARTMAP=$MAP \
    -e CS2_ADDITIONAL_ARGS="$ARGS" \
    cm2network/cs2

docker exec -it --user=0 "$CONTNAME" sh -c "dpkg --configure -a && apt-get update -y && apt-get install -y icu-devtools && apt-get install -y nano && apt-get install -y curl"

unset STEAMUSER
unset STEAMPASS
unset RCONPASS
unset SRVRPASS
unset VOLPATH
unset TOKEN
