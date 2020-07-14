library(googlesheets4)
library(stringr)
library(dplyr)
extract_bili_id = function(url)
{
  gsub(".*?/video\\/([[:alnum:]]*)\\/?", '\\1', url, perl=TRUE)
}


extract_youtube_id = function(url)
{
  gsub(".*?/youtu\\.be\\/([[:alnum:]]*)\\/?", '\\1', url, perl=TRUE)
}


gs4_deauth()
video_crew_url = "https://docs.google.com/spreadsheets/d/1vx2hxDEvmw23P5niUxTjeuHwdyjt_8W5d6lTfM0s-7g/edit#gid=14620051"
g4df = read_sheet(video_crew_url, sheet = "Real NMA", skip=5)
linkdf = g4df %>% select(Week, Day, `Bilibili Link`, `YouTube link`) %>% na.omit() %>% 
  mutate(bilibili_id=extract_bili_id(`Bilibili Link`), youtube_id=extract_youtube_id(`YouTube link`)) %>%
  filter(str_starts(bilibili_id, 'BV'))
write.table(linkdf %>% select(youtube_id, bilibili_id, Week, Day), 'video_ids.txt', quote=F, row.names = F, col.names = F)
