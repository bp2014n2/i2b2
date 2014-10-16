#!/bin/sh
#   Copyright 2002-2004 The Apache Software Foundation
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

echo '$1'
#java -cp . LauncherBootstrap -executablename launcher-demo demo
java -cp . LauncherBootstrap -executablename crc_analysis1 calculate_patient_breakdown_by_itemkey  $1 $2 $3 $4 $5
