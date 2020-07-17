#!/bin/zsh

find_line () # fine_line pattern filename
{
  file=$2
  patt=$1
  echo `grep -n "$patt" "$file" | cut -f1 -d:` # Need to recompute lineno since it changed.
}

replace_iframe_code ()
{
    fname=$1
    youtube_id=$2
    bilibili_id=$3
    lineno=`find_line "YouTubeVideo(id.*${youtube_id}" "$fname"`
    # Figure out if this code cell has an import line.
    has_import=`grep -b5 "YouTubeVideo(id.*${youtube_id}" "$fname" | grep "from IPython"`
    if [[ -z "${has_import}" ]]; then
      startline=${lineno}
    else
      startline=`expr ${lineno} - 1`
    fi

    endline=`expr $lineno + 1`
    insertline=`expr $startline - 1`
    # # Delete the youtube lines
    sed -i.back_1 -e "${startline},${endline}d" "$fname"    
    # Make the bilibili text
    sed "s/BILIID/$bilibili_id/" bilibili_code > this_bilicode
    # Insert bilibili text 
    sed  -i.back_2 "${insertline}r this_bilicode" ${fname}
} # end replace_iframe_code

replace_play_link ()
{
  fname=$1
  youtube_id=$2
  bilibili_id=$3
  yt_patt="Video available at https://youtube\.com/watch?v=${youtube_id}"
  bili_patt="Video available at https://www\.bilibili\.com/video/${bilibili_id}"
  sed -i.back_3 "s,${yt_patt},${bili_patt}," "$fname"
}


replace_src_link ()
{
  fname=$1
  youtube_id=$2
  bilibili_id=$3
  #        "            src=\"https://www.youtube.com/embed/wbZ60vdnoqw?fs=1\"\n",
  #bili_src='"            src=\"https://player.bilibili.com/player.html?bvid='"$bilibili_id"'&page=1?fs=1\"\\n",'
  yt_patt="www\.youtube\.com/embed/${youtube_id}"
  bili_patt="player\.bilibili\.com/player\.html\?bvid=${bilibili_id}"

  sed -i.back_3 "s,${yt_patt},${bili_patt}," "$fname"
}



# Get the link map from google sheets using this R script.
Rscript make_video_lists.R

rm -f files_to_reprocess.txt # delete the old file if it is there.
touch files_to_reprocess.txt # make an empty file to avoid errors.

while read vid; do # Go through each line of video_ids.txt

  # vid=`head -1 video_ids.txt` # FOR TESTING 
  youtube_id=`echo $vid | awk '{print $1}'`
  bilibili_id=`echo $vid | awk '{print $2}'`
  week=`echo $vid | awk '{print $3}'`
  day=`echo $vid | awk '{print $4}'`
  
  echo "Looking for youtube $youtube_id"
  search_dir=`ls ../tutorials | grep W${week}D${day}`
  find ../tutorials/${search_dir}/ -name "W${week}D${day}*ipynb" -type f -exec grep -l "YouTubeVideo(id.*${youtube_id}" {} \; > files_to_change
  # Use maxdepth to avoid processing student notebooks.

   if [[ -s files_to_change ]]; then
      echo "Found $youtube_id in:"
      cat files_to_change
   fi

  while read f2c; do
    echo "Found $youtube_id in $f2c"
    # fname=`head -1 files_to_change` # FOR TESTING 
    fname="$f2c"
    replace_iframe_code $fname $youtube_id $bilibili_id
    replace_src_link $fname $youtube_id $bilibili_id
    replace_play_link $fname $youtube_id $bilibili_id

    
    # save the files for later
    echo "$fname" >> files_to_reprocess.txt


  done <files_to_change 

done <video_ids.txt

./replace_github_links.sh

# Only need to rerun each notebook once!
cat files_to_reprocess.txt | sort | uniq > unique_files

while read f2p; do
   echo "Changed $f2p"
#  jupyter nbconvert --to notebook --inplace --execute "$f2p" --allow-errors
done <unique_files

