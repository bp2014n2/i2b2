<?php
$target_dir = "js-i2b2/cells/plugins/reportPlugin/assets/userfiles/" . $_POST["user"] . "/" . $_POST["type"] . "/";
$res = mkdir($target_dir, 0777, true);
$target_file = $target_dir . basename($_FILES["file"]["name"]);
$uploadOk = 1;
// Check if $uploadOk is set to 0 by an error
if ($uploadOk == 0) {
    echo "Sorry, your file was not uploaded.";
// if everything is ok, try to upload file
} else {
	if (move_uploaded_file($_FILES["file"]["tmp_name"], $target_file)) {
        echo "The file ". basename( $_FILES["file"]["name"]). " has been uploaded.";
    } else {
        echo "Sorry, there was an error uploading your file.";
    }
}
?>