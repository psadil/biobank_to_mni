library(targets)

# library(future)
# library(future.batchtools)
# plan(batchtools_sge, template = here::here("tools","sge.tmpl"))

# targets::tar_renv(extras=c("clustermq","qs","fst"))

options(clustermq.scheduler = "sge", clustermq.template = "sge_zmq.tmpl")
tar_option_set(format = "qs")

apply_warp <- function(
  subid, stat, contrast, 
  reffile = fs::path(Sys.getenv("FSLDIR"), "data", "standard","MNI152_T1_2mm_brain")){
  
  out_dir <- fs::path(
    "data","derivatives","fsl", glue::glue("sub-{subid}"), "ses-2","stats")
  fs::dir_create(out_dir)
  
  outfile <- fs::path(
    out_dir,
    glue::glue("sub-{subid}_ses-2_space-MNI152_contrast-{contrast}_{stat}"))
  
  status <- fslr::fsl_applywarp(
    infile = fs::path(
      "data-raw","bidsish",glue::glue("sub-{subid}"),"ses-2","non-bids","fMRI","tfMRI.feat","stats",
      glue::glue("{stat}{contrast}")),
    outfile = outfile,
    warpfile = fs::path(
      "data-raw","bidsish", glue::glue("sub-{subid}"),"ses-2","non-bids","fMRI","tfMRI.feat","reg",
      "example_func2standard_warp"),
    reffile = reffile,
    retimg = FALSE)
  
  if (status == 0){
    fsl_applywarp
  }
}

list(
  tar_target(
    avail,
    fs::path("data-raw","avail.txt"),
    format = "file",
    deployment = "main"),
  tar_target(
    subid,
    readr::read_lines(avail),
    format = "fst_tbl",
    deployment = "main"),
  tar_target(contrast, 5, deployment = "main"),
  tar_target(stat, c("cope"), deployment = "main"),
  tar_target(
    mni_cope,
    apply_warp(subid=subid, contrast=contrast, stat=stat),
    format = "file",
    pattern = cross(subid, contrast, stat),
    storage = "worker",
    retrieval = "worker",
    resources = tar_resources(
      clustermq = tar_resources_clustermq(
        template=list(mem_free = "256M")))
    # resources = list(
    #   batchtools_sge,
    #   template = here::here("tools","sge.tmpl"),
    #   resources = list(mem_free = "256M"))))
  )
)
