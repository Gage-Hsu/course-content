#!/bin/zsh

#!/bin/zsh

find_line () # fine_line pattern filename
{
  file=$2
  patt=$1
  echo `grep -n "$patt" "$file" | cut -f1 -d:` # Need to recompute lineno since it changed.
}



insert_thumbnail(){
  fname="$1"
  bilibili_patt="bvid=$2"
  url="https://www.bilibili.com/video/$2"
  insert_at=`expr $(grep -niro $bilibili_patt $fname -b10  | grep "text/html" | cut -d- -f 2) - 1`
  python create_jpg_file.py $url
  sed -i.back_4 "${insert_at}r this_jpg" $fname
}

# Get the link map from google sheets using this R script.
Rscript make_video_lists.R

rm -f files_to_reprocess.txt # delete the old file if it is there.
touch files_to_reprocess.txt # make an empty file to avoid errors.

while read vid; do # Go through each line of video_ids.txt

  # vid=`head -1 video_ids.txt` # FOR TESTING 
  bilibili_id=`echo $vid | awk '{print $2}'`
  week=`echo $vid | awk '{print $3}'`
  day=`echo $vid | awk '{print $4}'`
  
  echo "Looking for bilibili $bilibili_id"
  search_dir=`ls ../tutorials | grep W${week}D${day}`
  find ../tutorials/${search_dir}/ -name "W${week}D${day}*ipynb" -type f -exec grep -l "video/${bilibili_id}" {} \; > files_to_change
  # Use maxdepth to avoid processing student notebooks.

   if [[ -s files_to_change ]]; then
      echo "Found $bilibili_id in:"
      cat files_to_change
   fi

  while read f2c; do
    echo "Found $bilibili_id in $f2c"
    # fname=`head -1 files_to_change` # FOR TESTING 
    fname="$f2c"
    insert_thumbnail $fname $bilibili_id
    
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

