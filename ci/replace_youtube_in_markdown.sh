#!/bin/zsh

find_line () # fine_line pattern filename
{
  file=$2
  patt=$1
  echo `grep -n "$patt" "$file" | cut -f1 -d:` # Need to recompute lineno since it changed.
}


replace_link ()
{
  fname=$1
  youtube_id=$2
  bilibili_id=$3
  yt_patt="http.*${youtube_id}"
  bili_patt="\(https://www\.bilibili\.com/video/${bilibili_id}\)"
  sed -i.back_0 "s,${yt_patt},${bili_patt}," "$fname"
}


# Get the link map from google sheets using this R script.
Rscript make_video_lists.R

rm -f files_to_reprocess.txt # delete the old file if it is there.
touch files_to_reprocess.txt # make an empty file to avoid errors.

while read vid; do # Go through each line of video_ids.txt

  # vid=`head -1 video_ids.txt` # FOR TESTING 
  youtube_id=`echo $vid | awk '{print $1}'`
  bilibili_id=`echo $vid | awk '{print $2}'`
  
  echo "Looking for youtube $youtube_id"
  find .. -iname "*md" -type f -exec grep -l -- "$youtube_id" {} \; > files_to_change
  # Use maxdepth to avoid processing student notebooks.

   if [[ -s files_to_change ]]; then
      echo "Found $youtube_id in:"
      cat files_to_change
   fi

  while read f2c; do
    echo "Found $youtube_id in $f2c"
    # fname=`head -1 files_to_change` # FOR TESTING 
    fname="$f2c"
    replace_link $fname $youtube_id $bilibili_id
    
    
    # save the files for later
    echo "$fname" >> files_to_reprocess.txt


  done <files_to_change 

done <video_ids.txt

# Only need to rerun each notebook once!
cat files_to_reprocess.txt | sort | uniq > unique_files

while read f2p; do
   echo "Changed $f2p"
#  jupyter nbconvert --to notebook --inplace --execute "$f2p" --allow-errors
done <unique_files

