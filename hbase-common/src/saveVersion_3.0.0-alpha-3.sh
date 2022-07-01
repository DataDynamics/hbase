#!/usr/bin/env bash

# This file is used to generate the annotation of package info that
# records the user, url, revision and timestamp.

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

unset LANG
unset LC_CTYPE

version=$1
javaOutputDirectory="$2/java/"
nativeOutputDirectory="$2/native/utils/"

pushd .
cd ..

user=$(whoami | sed -n -e "s/\\\/\\\\\\\\/p")
if [ "$user" == "" ]
then
  user=$(whoami)
fi
date=$(date)
cwd=$(pwd)
if [ -d .svn ]; then
  revision=$( (svn info | sed -n -e "s/Last Changed Rev: \(.*\)/\1/p") || true)
  url=$( (svn info | sed -n -e 's/^URL: \(.*\)/\1/p') || true)
elif [ -d .git ]; then
  # revision=$(git log -1 --no-show-signature --pretty=format:"%H" || true)
  revision=$(git log -1 --pretty=format:"%H" || true)
  hostname=$(hostname)
  url="git://${hostname}${cwd}"
fi
if [ -z "${revision}" ]; then
  echo "[WARN] revision info is empty! either we're not in VCS or VCS commands failed." >&2
  revision="Unknown"
  url="file://$cwd"
fi
if ! [ -x "$(command -v openssl)" ]; then
  if ! [ -x "$(command -v gpg)" ]; then
    srcChecksum="Unknown"
  else
    srcChecksum=$(find hbase-*/src/main/ | grep -e "\.java" -e "\.proto" | LC_ALL=C sort | xargs gpg --print-md sha512 | gpg --print-md sha512 | tr '\n' ' ' | sed 's/[[:space:]]*//g')
  fi
else
  srcChecksum=$(find hbase-*/src/main/ | grep -e "\.java" -e "\.proto" | LC_ALL=C sort | xargs openssl dgst -sha512 | openssl dgst -sha512 | sed 's/^.* //')
fi
popd

mkdir -p "$javaOutputDirectory/org/apache/hadoop/hbase"
cat >"$javaOutputDirectory/org/apache/hadoop/hbase/Version.java" <<EOF
/**
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
/*
 * Generated by src/saveVersion.sh
 */
package org.apache.hadoop.hbase;

import org.apache.yetus.audience.InterfaceAudience;

@InterfaceAudience.Private
@edu.umd.cs.findbugs.annotations.SuppressWarnings(value="DM_STRING_CTOR",
  justification="Intentional; to be modified in test")
public class Version {
  public static final String version = new String("$version");
  public static final String revision = "$revision";
  public static final String user = "$user";
  public static final String date = "$date";
  public static final String url = "$url";
  public static final String srcChecksum = "$srcChecksum";
}
EOF

mkdir -p "$nativeOutputDirectory"
cat > "$nativeOutputDirectory/version.h" <<EOF
/**
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
/*
 * Generated by src/saveVersion.sh from hbase-common.
 */

#pragma once

namespace hbase {
class Version {
  public:
    static constexpr const char* version = "$version";
    static constexpr const char* revision = "$revision";
    static constexpr const char* user = "$user";
    static constexpr const char* date = "$date";
    static constexpr const char* url = "$url";
    static constexpr const char* src_checksum = "$srcChecksum";
};
} /* namespace hbase */
EOF
