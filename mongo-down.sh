kill $(ps -aef | grep mongo[s,d] | awk '{ print $2 }' )
