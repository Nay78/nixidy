# This file was generated with nixidy resource generator, do not edit.
{
  lib,
  options,
  config,
  ...
}:

with lib;

let
  hasAttrNotNull = attr: set: hasAttr attr set && set.${attr} != null;

  attrsToList =
    values:
    if values != null then
      sort (
        a: b:
        if (hasAttrNotNull "_priority" a && hasAttrNotNull "_priority" b) then
          a._priority < b._priority
        else
          false
      ) (mapAttrsToList (n: v: v) values)
    else
      values;

  getDefaults =
    resource: group: version: kind:
    catAttrs "default" (
      filter (
        default:
        (default.resource == null || default.resource == resource)
        && (default.group == null || default.group == group)
        && (default.version == null || default.version == version)
        && (default.kind == null || default.kind == kind)
      ) config.defaults
    );

  types = lib.types // rec {
    str = mkOptionType {
      name = "str";
      description = "string";
      check = isString;
      merge = mergeEqualOption;
    };

    # Either value of type `finalType` or `coercedType`, the latter is
    # converted to `finalType` using `coerceFunc`.
    coercedTo =
      coercedType: coerceFunc: finalType:
      mkOptionType rec {
        inherit (finalType) getSubOptions getSubModules;

        name = "coercedTo";
        description = "${finalType.description} or ${coercedType.description}";
        check = x: finalType.check x || coercedType.check x;
        merge =
          loc: defs:
          let
            coerceVal =
              val:
              if finalType.check val then
                val
              else
                let
                  coerced = coerceFunc val;
                in
                assert finalType.check coerced;
                coerced;

          in
          finalType.merge loc (map (def: def // { value = coerceVal def.value; }) defs);
        substSubModules = m: coercedTo coercedType coerceFunc (finalType.substSubModules m);
        typeMerge = t1: t2: null;
        functor = (defaultFunctor name) // {
          wrapped = finalType;
        };
      };
  };

  mkOptionDefault = mkOverride 1001;

  mergeValuesByKey =
    attrMergeKey: listMergeKeys: values:
    listToAttrs (
      imap0 (
        i: value:
        nameValuePair (
          if hasAttr attrMergeKey value then
            if isAttrs value.${attrMergeKey} then
              toString value.${attrMergeKey}.content
            else
              (toString value.${attrMergeKey})
          else
            # generate merge key for list elements if it's not present
            "__kubenix_list_merge_key_"
            + (concatStringsSep "" (
              map (
                key: if isAttrs value.${key} then toString value.${key}.content else (toString value.${key})
              ) listMergeKeys
            ))
        ) (value // { _priority = i; })
      ) values
    );

  submoduleOf =
    ref:
    types.submodule (
      { name, ... }:
      {
        options = definitions."${ref}".options or { };
        config = definitions."${ref}".config or { };
      }
    );

  globalSubmoduleOf =
    ref:
    types.submodule (
      { name, ... }:
      {
        options = config.definitions."${ref}".options or { };
        config = config.definitions."${ref}".config or { };
      }
    );

  submoduleWithMergeOf =
    ref: mergeKey:
    types.submodule (
      { name, ... }:
      let
        convertName =
          name: if definitions."${ref}".options.${mergeKey}.type == types.int then toInt name else name;
      in
      {
        options = definitions."${ref}".options // {
          # position in original array
          _priority = mkOption {
            type = types.nullOr types.int;
            default = null;
          };
        };
        config = definitions."${ref}".config // {
          ${mergeKey} = mkOverride 1002 (
            # use name as mergeKey only if it is not coming from mergeValuesByKey
            if (!hasPrefix "__kubenix_list_merge_key_" name) then convertName name else null
          );
        };
      }
    );

  submoduleForDefinition =
    ref: resource: kind: group: version:
    let
      apiVersion = if group == "core" then version else "${group}/${version}";
    in
    types.submodule (
      { name, ... }:
      {
        inherit (definitions."${ref}") options;

        imports = getDefaults resource group version kind;
        config = mkMerge [
          definitions."${ref}".config
          {
            kind = mkOptionDefault kind;
            apiVersion = mkOptionDefault apiVersion;

            # metdata.name cannot use option default, due deep config
            metadata.name = mkOptionDefault name;
          }
        ];
      }
    );

  coerceAttrsOfSubmodulesToListByKey =
    ref: attrMergeKey: listMergeKeys:
    (types.coercedTo (types.listOf (submoduleOf ref)) (mergeValuesByKey attrMergeKey listMergeKeys) (
      types.attrsOf (submoduleWithMergeOf ref attrMergeKey)
    ));

  definitions = {
    "stackgres.io.v1.SGBackup" = {

      options = {
        "apiVersion" = mkOption {
          description = "\nAPIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources\n";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "\nKind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds\n";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "";
          type = (submoduleOf "stackgres.io.v1.SGBackupSpec");
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGBackupStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupSpec" = {

      options = {
        "managedLifecycle" = mkOption {
          description = "Indicate if this backup is not permanent and should be removed by the automated\n retention policy. Default is `false`.\n";
          type = (types.nullOr types.bool);
        };
        "maxRetries" = mkOption {
          description = "The maximum number of retries the backup operation is allowed to do after a failure.\n\nA value of `0` (zero) means no retries are made. Defaults to: `3`.\n";
          type = (types.nullOr types.int);
        };
        "reconciliationTimeout" = mkOption {
          description = "Allow to set a timeout for the reconciliation process that take place after the backup.\n\nIf not set defaults to 300 (5 minutes). If set to 0 it will disable timeout.\n\nFailure of reconciliation will not make the backup fail and will be re-tried the next time a SGBackup\n or shecduled backup Job take place.\n";
          type = (types.nullOr types.int);
        };
        "sgCluster" = mkOption {
          description = "The name of the `SGCluster` from which this backup is/will be taken.\n\nIf this is a copy of an existing completed backup in a different namespace\n the value must be prefixed with the namespace of the source backup and a\n dot `.` (e.g. `<cluster namespace>.<cluster name>`) or have the same value\n if the source backup is also a copy.\n";
          type = (types.nullOr types.str);
        };
        "timeout" = mkOption {
          description = "Allow to set a timeout for the backup creation.\n\nIf not set it will be disabled and the backup operation will continue until the backup completes or fail. If set to 0 is the same as not being set.\n\nMake sure to set a reasonable high value in order to allow for any unexpected delays during backup creation (network low bandwidth, disk low throughput and so forth).\n";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "managedLifecycle" = mkOverride 1002 null;
        "maxRetries" = mkOverride 1002 null;
        "reconciliationTimeout" = mkOverride 1002 null;
        "sgCluster" = mkOverride 1002 null;
        "timeout" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatus" = {

      options = {
        "backupInformation" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGBackupStatusBackupInformation"));
        };
        "backupPath" = mkOption {
          description = "The path were the backup is stored.\n";
          type = (types.nullOr types.str);
        };
        "internalName" = mkOption {
          description = "The name of the backup.\n";
          type = (types.nullOr types.str);
        };
        "process" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGBackupStatusProcess"));
        };
        "sgBackupConfig" = mkOption {
          description = "The backup configuration used to perform this backup.";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfig"));
        };
        "volumeSnapshot" = mkOption {
          description = "The volume snapshot configuration used to restore this backup.";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGBackupStatusVolumeSnapshot"));
        };
      };

      config = {
        "backupInformation" = mkOverride 1002 null;
        "backupPath" = mkOverride 1002 null;
        "internalName" = mkOverride 1002 null;
        "process" = mkOverride 1002 null;
        "sgBackupConfig" = mkOverride 1002 null;
        "volumeSnapshot" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatusBackupInformation" = {

      options = {
        "controlData" = mkOption {
          description = "An object containing data from the output of pg_controldata on the backup.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGBackupStatusBackupInformationControlData"));
        };
        "hostname" = mkOption {
          description = "Hostname of the instance where the backup is taken from.\n";
          type = (types.nullOr types.str);
        };
        "lsn" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGBackupStatusBackupInformationLsn"));
        };
        "pgData" = mkOption {
          description = "Data directory where the backup is taken from.\n";
          type = (types.nullOr types.str);
        };
        "postgresVersion" = mkOption {
          description = "Postgres version of the server where the backup is taken from.\n";
          type = (types.nullOr types.str);
        };
        "size" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGBackupStatusBackupInformationSize"));
        };
        "sourcePod" = mkOption {
          description = "Pod where the backup is taken from.\n";
          type = (types.nullOr types.str);
        };
        "startWalFile" = mkOption {
          description = "WAL segment file name when the backup was started.\n";
          type = (types.nullOr types.str);
        };
        "systemIdentifier" = mkOption {
          description = "Postgres *system identifier* of the cluster this backup is taken from.\n";
          type = (types.nullOr types.str);
        };
        "timeline" = mkOption {
          description = "Backup timeline.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "controlData" = mkOverride 1002 null;
        "hostname" = mkOverride 1002 null;
        "lsn" = mkOverride 1002 null;
        "pgData" = mkOverride 1002 null;
        "postgresVersion" = mkOverride 1002 null;
        "size" = mkOverride 1002 null;
        "sourcePod" = mkOverride 1002 null;
        "startWalFile" = mkOverride 1002 null;
        "systemIdentifier" = mkOverride 1002 null;
        "timeline" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatusBackupInformationControlData" = {

      options = {
        "Backup end location" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Backup start location" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Blocks per segment of large relation" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Bytes per WAL segment" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Catalog version number" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Data page checksum version" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Database block size" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Database cluster state" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Database system identifier" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Date/time type storage" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "End-of-backup record required" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Fake LSN counter for unlogged rels" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Float4 argument passing" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Float8 argument passing" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Latest checkpoint location" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Latest checkpoint's NextMultiOffset" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Latest checkpoint's NextMultiXactId" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Latest checkpoint's NextOID" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Latest checkpoint's NextXID" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Latest checkpoint's PrevTimeLineID" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Latest checkpoint's REDO WAL file" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Latest checkpoint's REDO location" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Latest checkpoint's TimeLineID" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Latest checkpoint's full_page_writes" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Latest checkpoint's newestCommitTsXid" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Latest checkpoint's oldestActiveXID" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Latest checkpoint's oldestCommitTsXid" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Latest checkpoint's oldestMulti's DB" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Latest checkpoint's oldestMultiXid" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Latest checkpoint's oldestXID" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Latest checkpoint's oldestXID's DB" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Maximum columns in an index" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Maximum data alignment" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Maximum length of identifiers" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Maximum size of a TOAST chunk" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Min recovery ending loc's timeline" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Minimum recovery ending location" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Mock authentication nonce" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Size of a large-object chunk" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "Time of latest checkpoint" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "WAL block size" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "max_connections setting" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "max_locks_per_xact setting" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "max_prepared_xacts setting" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "max_wal_senders setting" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "max_worker_processes setting" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "pg_control last modified" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "pg_control version number" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "track_commit_timestamp setting" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "wal_level setting" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "wal_log_hints setting" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "Backup end location" = mkOverride 1002 null;
        "Backup start location" = mkOverride 1002 null;
        "Blocks per segment of large relation" = mkOverride 1002 null;
        "Bytes per WAL segment" = mkOverride 1002 null;
        "Catalog version number" = mkOverride 1002 null;
        "Data page checksum version" = mkOverride 1002 null;
        "Database block size" = mkOverride 1002 null;
        "Database cluster state" = mkOverride 1002 null;
        "Database system identifier" = mkOverride 1002 null;
        "Date/time type storage" = mkOverride 1002 null;
        "End-of-backup record required" = mkOverride 1002 null;
        "Fake LSN counter for unlogged rels" = mkOverride 1002 null;
        "Float4 argument passing" = mkOverride 1002 null;
        "Float8 argument passing" = mkOverride 1002 null;
        "Latest checkpoint location" = mkOverride 1002 null;
        "Latest checkpoint's NextMultiOffset" = mkOverride 1002 null;
        "Latest checkpoint's NextMultiXactId" = mkOverride 1002 null;
        "Latest checkpoint's NextOID" = mkOverride 1002 null;
        "Latest checkpoint's NextXID" = mkOverride 1002 null;
        "Latest checkpoint's PrevTimeLineID" = mkOverride 1002 null;
        "Latest checkpoint's REDO WAL file" = mkOverride 1002 null;
        "Latest checkpoint's REDO location" = mkOverride 1002 null;
        "Latest checkpoint's TimeLineID" = mkOverride 1002 null;
        "Latest checkpoint's full_page_writes" = mkOverride 1002 null;
        "Latest checkpoint's newestCommitTsXid" = mkOverride 1002 null;
        "Latest checkpoint's oldestActiveXID" = mkOverride 1002 null;
        "Latest checkpoint's oldestCommitTsXid" = mkOverride 1002 null;
        "Latest checkpoint's oldestMulti's DB" = mkOverride 1002 null;
        "Latest checkpoint's oldestMultiXid" = mkOverride 1002 null;
        "Latest checkpoint's oldestXID" = mkOverride 1002 null;
        "Latest checkpoint's oldestXID's DB" = mkOverride 1002 null;
        "Maximum columns in an index" = mkOverride 1002 null;
        "Maximum data alignment" = mkOverride 1002 null;
        "Maximum length of identifiers" = mkOverride 1002 null;
        "Maximum size of a TOAST chunk" = mkOverride 1002 null;
        "Min recovery ending loc's timeline" = mkOverride 1002 null;
        "Minimum recovery ending location" = mkOverride 1002 null;
        "Mock authentication nonce" = mkOverride 1002 null;
        "Size of a large-object chunk" = mkOverride 1002 null;
        "Time of latest checkpoint" = mkOverride 1002 null;
        "WAL block size" = mkOverride 1002 null;
        "max_connections setting" = mkOverride 1002 null;
        "max_locks_per_xact setting" = mkOverride 1002 null;
        "max_prepared_xacts setting" = mkOverride 1002 null;
        "max_wal_senders setting" = mkOverride 1002 null;
        "max_worker_processes setting" = mkOverride 1002 null;
        "pg_control last modified" = mkOverride 1002 null;
        "pg_control version number" = mkOverride 1002 null;
        "track_commit_timestamp setting" = mkOverride 1002 null;
        "wal_level setting" = mkOverride 1002 null;
        "wal_log_hints setting" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatusBackupInformationLsn" = {

      options = {
        "end" = mkOption {
          description = "LSN of when the backup finished.\n";
          type = (types.nullOr types.str);
        };
        "start" = mkOption {
          description = "LSN of when the backup started.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "end" = mkOverride 1002 null;
        "start" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatusBackupInformationSize" = {

      options = {
        "compressed" = mkOption {
          description = "Size (in bytes) of the compressed backup.\n";
          type = (types.nullOr types.int);
        };
        "uncompressed" = mkOption {
          description = "Size (in bytes) of the uncompressed backup.\n";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "compressed" = mkOverride 1002 null;
        "uncompressed" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatusProcess" = {

      options = {
        "failure" = mkOption {
          description = "If the status is `failed` this field will contain a message indicating the failure reason.\n";
          type = (types.nullOr types.str);
        };
        "jobPod" = mkOption {
          description = "Name of the pod assigned to the backup. StackGres utilizes internally a locking mechanism based on the pod name of the job that creates the backup.\n";
          type = (types.nullOr types.str);
        };
        "managedLifecycle" = mkOption {
          description = "Status (may be transient) until converging to `spec.managedLifecycle`.\n";
          type = (types.nullOr types.bool);
        };
        "status" = mkOption {
          description = "Status of the backup.\n";
          type = (types.nullOr types.str);
        };
        "timing" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGBackupStatusProcessTiming"));
        };
      };

      config = {
        "failure" = mkOverride 1002 null;
        "jobPod" = mkOverride 1002 null;
        "managedLifecycle" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "timing" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatusProcessTiming" = {

      options = {
        "end" = mkOption {
          description = "End time of backup.\n";
          type = (types.nullOr types.str);
        };
        "start" = mkOption {
          description = "Start time of backup.\n";
          type = (types.nullOr types.str);
        };
        "stored" = mkOption {
          description = "Time at which the backup is safely stored in the object storage.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "end" = mkOverride 1002 null;
        "start" = mkOverride 1002 null;
        "stored" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfig" = {

      options = {
        "baseBackups" = mkOption {
          description = "Back backups configuration.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigBaseBackups"));
        };
        "storage" = mkOption {
          description = "Object Storage configuration\n";
          type = (submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorage");
        };
      };

      config = {
        "baseBackups" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigBaseBackups" = {

      options = {
        "compression" = mkOption {
          description = "Select the backup compression algorithm. Possible options are: lz4, lzma, zstd, brotli. The default method is `lz4`. LZ4 is the fastest method, but compression ratio is the worst. LZMA is way slower, but it compresses backups about 6 times better than LZ4. Brotli is a good trade-off between speed and compression ratio, being about 3 times better than LZ4.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "compression" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorage" = {

      options = {
        "azureBlob" = mkOption {
          description = "Azure Blob Storage configuration.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageAzureBlob"));
        };
        "encryption" = mkOption {
          description = "Section to configure object storage encryption of stored files.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageEncryption"));
        };
        "gcs" = mkOption {
          description = "Google Cloud Storage configuration.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageGcs"));
        };
        "s3" = mkOption {
          description = "Amazon Web Services S3 configuration.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3"));
        };
        "s3Compatible" = mkOption {
          description = "AWS S3-Compatible API configuration";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3Compatible")
          );
        };
        "type" = mkOption {
          description = "Determine the type of object storage used for storing the base backups and WAL segments.\n      Possible values:\n      *  `s3`: Amazon Web Services S3 (Simple Storage Service).\n      *  `s3Compatible`: non-AWS services that implement a compatibility API with AWS S3.\n      *  `gcs`: Google Cloud Storage.\n      *  `azureBlob`: Microsoft Azure Blob Storage.\n";
          type = types.str;
        };
      };

      config = {
        "azureBlob" = mkOverride 1002 null;
        "encryption" = mkOverride 1002 null;
        "gcs" = mkOverride 1002 null;
        "s3" = mkOverride 1002 null;
        "s3Compatible" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageAzureBlob" = {

      options = {
        "azureCredentials" = mkOption {
          description = "The credentials to access Azure Blob Storage for writing and reading.\n";
          type = (submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageAzureBlobAzureCredentials");
        };
        "bucket" = mkOption {
          description = "Azure Blob Storage bucket name.\n";
          type = types.str;
        };
      };

      config = { };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageAzureBlobAzureCredentials" = {

      options = {
        "secretKeySelectors" = mkOption {
          description = "Kubernetes [SecretKeySelector](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#secretkeyselector-v1-core)(s) to reference the Secret(s) that contain the information about the `azureCredentials`. . Note that you may use the same or different Secrets for the `storageAccount` and the `accessKey`. In the former case, the `keys` that identify each must be, obviously, different.\n";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageAzureBlobAzureCredentialsSecretKeySelectors"
            )
          );
        };
      };

      config = {
        "secretKeySelectors" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageAzureBlobAzureCredentialsSecretKeySelectors" = {

      options = {
        "accessKey" = mkOption {
          description = "The [storage account access key](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-keys-manage?tabs=azure-portal).\n";
          type = (
            submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageAzureBlobAzureCredentialsSecretKeySelectorsAccessKey"
          );
        };
        "storageAccount" = mkOption {
          description = "The [Storage Account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview?toc=/azure/storage/blobs/toc.json) that contains the Blob bucket to be used.\n";
          type = (
            submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageAzureBlobAzureCredentialsSecretKeySelectorsStorageAccount"
          );
        };
      };

      config = { };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageAzureBlobAzureCredentialsSecretKeySelectorsAccessKey" =
      {

        options = {
          "key" = mkOption {
            description = "The key of the secret to select from. Must be a valid secret key.\n";
            type = types.str;
          };
          "name" = mkOption {
            description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).\n";
            type = types.str;
          };
        };

        config = { };

      };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageAzureBlobAzureCredentialsSecretKeySelectorsStorageAccount" =
      {

        options = {
          "key" = mkOption {
            description = "The key of the secret to select from. Must be a valid secret key.\n";
            type = types.str;
          };
          "name" = mkOption {
            description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).\n";
            type = types.str;
          };
        };

        config = { };

      };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageEncryption" = {

      options = {
        "method" = mkOption {
          description = "Select the storage encryption method.\n\nPossible options are:\n\n* `sodium`: will use libsodium to encrypt the files stored.\n* `openpgp`: will use OpenPGP standard to encrypt the files stored.\n\nWhen not set no encryption will be applied to stored files.\n";
          type = (types.nullOr types.str);
        };
        "openpgp" = mkOption {
          description = "OpenPGP encryption configuration.";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageEncryptionOpenpgp")
          );
        };
        "sodium" = mkOption {
          description = "libsodium encryption configuration.";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageEncryptionSodium")
          );
        };
      };

      config = {
        "method" = mkOverride 1002 null;
        "openpgp" = mkOverride 1002 null;
        "sodium" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageEncryptionOpenpgp" = {

      options = {
        "key" = mkOption {
          description = "To configure encryption and decryption with OpenPGP standard. You can join multiline\n key using `\\n` symbols into one line (mostly used in case of daemontools and envdir).\n";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageEncryptionOpenpgpKey")
          );
        };
        "keyPassphrase" = mkOption {
          description = "If your private key is encrypted with a passphrase, you should set passphrase for decrypt.\n";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageEncryptionOpenpgpKeyPassphrase"
            )
          );
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "keyPassphrase" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageEncryptionOpenpgpKey" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from. Must be a valid secret key.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageEncryptionOpenpgpKeyPassphrase" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from. Must be a valid secret key.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageEncryptionSodium" = {

      options = {
        "key" = mkOption {
          description = "To configure encryption and decryption with libsodium an algorithm that only requires\n a secret key is used. libsodium keys are fixed-size keys of 32 bytes. For optimal\n cryptographic security, it is recommened to use a random 32 byte key. To generate a\n random key, you can something like `openssl rand -hex 32` (set `keyTransform` to `hex`)\n or `openssl rand -base64 32` (set `keyTransform` to `base64`).\n";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageEncryptionSodiumKey")
          );
        };
        "keyTransform" = mkOption {
          description = "The transform that will be applied to the `key` to get the required 32 byte key.\n Supported transformations are `base64`, `hex` or `none` (default). The option\n none exists for backwards compatbility, the user input will be converted to 32\n byte either via truncation or by zero-padding.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "keyTransform" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageEncryptionSodiumKey" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from. Must be a valid secret key.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageGcs" = {

      options = {
        "bucket" = mkOption {
          description = "GCS bucket name.\n";
          type = types.str;
        };
        "gcpCredentials" = mkOption {
          description = "The credentials to access GCS for writing and reading.\n";
          type = (submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageGcsGcpCredentials");
        };
      };

      config = { };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageGcsGcpCredentials" = {

      options = {
        "fetchCredentialsFromMetadataService" = mkOption {
          description = "If true, the credentials will be fetched from the GCE/GKE metadata service and the field `secretKeySelectors` have to be set to null or omitted.\n\nThis is useful when running StackGres inside a GKE cluster using [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity).\n";
          type = (types.nullOr types.bool);
        };
        "secretKeySelectors" = mkOption {
          description = "A Kubernetes [SecretKeySelector](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#secretkeyselector-v1-core) to reference the Secrets that contain the information about the Service Account to access GCS.\n";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageGcsGcpCredentialsSecretKeySelectors"
            )
          );
        };
      };

      config = {
        "fetchCredentialsFromMetadataService" = mkOverride 1002 null;
        "secretKeySelectors" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageGcsGcpCredentialsSecretKeySelectors" = {

      options = {
        "serviceAccountJSON" = mkOption {
          description = "A service account key from GCP. In JSON format, as downloaded from the GCP Console.\n";
          type = (
            submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageGcsGcpCredentialsSecretKeySelectorsServiceAccountJSON"
          );
        };
      };

      config = { };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageGcsGcpCredentialsSecretKeySelectorsServiceAccountJSON" =
      {

        options = {
          "key" = mkOption {
            description = "The key of the secret to select from. Must be a valid secret key.\n";
            type = types.str;
          };
          "name" = mkOption {
            description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).\n";
            type = types.str;
          };
        };

        config = { };

      };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3" = {

      options = {
        "awsCredentials" = mkOption {
          description = "The credentials to access AWS S3 for writing and reading.\n";
          type = (submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3AwsCredentials");
        };
        "bucket" = mkOption {
          description = "AWS S3 bucket name.\n";
          type = types.str;
        };
        "region" = mkOption {
          description = "The AWS S3 region. The Region may be detected using s3:GetBucketLocation, but if you wish to avoid giving permissions to this API call or forbid it from the applicable IAM policy, you must then specify this property.\n";
          type = (types.nullOr types.str);
        };
        "storageClass" = mkOption {
          description = "The [Amazon S3 Storage Class](https://aws.amazon.com/s3/storage-classes/) to use for the backup object storage. By default, the `STANDARD` storage class is used. Other supported values include `STANDARD_IA` for Infrequent Access and `REDUCED_REDUNDANCY`.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "region" = mkOverride 1002 null;
        "storageClass" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3AwsCredentials" = {

      options = {
        "secretKeySelectors" = mkOption {
          description = "Kubernetes [SecretKeySelector](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#secretkeyselector-v1-core)(s) to reference the Secrets that contain the information about the `awsCredentials`. Note that you may use the same or different Secrets for the `accessKeyId` and the `secretAccessKey`. In the former case, the `keys` that identify each must be, obviously, different.\n";
          type = (
            submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3AwsCredentialsSecretKeySelectors"
          );
        };
      };

      config = { };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3AwsCredentialsSecretKeySelectors" = {

      options = {
        "accessKeyId" = mkOption {
          description = "AWS [access key ID](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys). For example, `AKIAIOSFODNN7EXAMPLE`.\n";
          type = (
            submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3AwsCredentialsSecretKeySelectorsAccessKeyId"
          );
        };
        "secretAccessKey" = mkOption {
          description = "AWS [secret access key](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys). For example, `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`.\n";
          type = (
            submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3AwsCredentialsSecretKeySelectorsSecretAccessKey"
          );
        };
      };

      config = { };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3AwsCredentialsSecretKeySelectorsAccessKeyId" =
      {

        options = {
          "key" = mkOption {
            description = "The key of the secret to select from. Must be a valid secret key.\n";
            type = types.str;
          };
          "name" = mkOption {
            description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).\n";
            type = types.str;
          };
        };

        config = { };

      };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3AwsCredentialsSecretKeySelectorsSecretAccessKey" =
      {

        options = {
          "key" = mkOption {
            description = "The key of the secret to select from. Must be a valid secret key.\n";
            type = types.str;
          };
          "name" = mkOption {
            description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).\n";
            type = types.str;
          };
        };

        config = { };

      };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3Compatible" = {

      options = {
        "awsCredentials" = mkOption {
          description = "The credentials to access AWS S3 for writing and reading.\n";
          type = (
            submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3CompatibleAwsCredentials"
          );
        };
        "bucket" = mkOption {
          description = "Bucket name.\n";
          type = types.str;
        };
        "enablePathStyleAddressing" = mkOption {
          description = "Enable path-style addressing (i.e. `http://s3.amazonaws.com/BUCKET/KEY`) when connecting to an S3-compatible service that lacks support for sub-domain style bucket URLs (i.e. `http://BUCKET.s3.amazonaws.com/KEY`).\n\nDefaults to false.\n";
          type = (types.nullOr types.bool);
        };
        "endpoint" = mkOption {
          description = "Overrides the default url to connect to an S3-compatible service.\nFor example: `http://s3-like-service:9000`.\n";
          type = (types.nullOr types.str);
        };
        "region" = mkOption {
          description = "The AWS S3 region. The Region may be detected using s3:GetBucketLocation, but if you wish to avoid giving permissions to this API call or forbid it from the applicable IAM policy, you must then specify this property.\n";
          type = (types.nullOr types.str);
        };
        "storageClass" = mkOption {
          description = "The [Amazon S3 Storage Class](https://aws.amazon.com/s3/storage-classes/) to use for the backup object storage. By default, the `STANDARD` storage class is used. Other supported values include `STANDARD_IA` for Infrequent Access and `REDUCED_REDUNDANCY`.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "enablePathStyleAddressing" = mkOverride 1002 null;
        "endpoint" = mkOverride 1002 null;
        "region" = mkOverride 1002 null;
        "storageClass" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3CompatibleAwsCredentials" = {

      options = {
        "secretKeySelectors" = mkOption {
          description = "Kubernetes [SecretKeySelector](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#secretkeyselector-v1-core)(s) to reference the Secret(s) that contain the information about the `awsCredentials`. Note that you may use the same or different Secrets for the `accessKeyId` and the `secretAccessKey`. In the former case, the `keys` that identify each must be, obviously, different.\n";
          type = (
            submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3CompatibleAwsCredentialsSecretKeySelectors"
          );
        };
      };

      config = { };

    };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3CompatibleAwsCredentialsSecretKeySelectors" =
      {

        options = {
          "accessKeyId" = mkOption {
            description = "AWS [access key ID](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys). For example, `AKIAIOSFODNN7EXAMPLE`.\n";
            type = (
              submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3CompatibleAwsCredentialsSecretKeySelectorsAccessKeyId"
            );
          };
          "caCertificate" = mkOption {
            description = "CA Certificate file to be used when connecting to the S3 Compatible Service.\n";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3CompatibleAwsCredentialsSecretKeySelectorsCaCertificate"
              )
            );
          };
          "secretAccessKey" = mkOption {
            description = "AWS [secret access key](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys). For example, `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`.\n";
            type = (
              submoduleOf "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3CompatibleAwsCredentialsSecretKeySelectorsSecretAccessKey"
            );
          };
        };

        config = {
          "caCertificate" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3CompatibleAwsCredentialsSecretKeySelectorsAccessKeyId" =
      {

        options = {
          "key" = mkOption {
            description = "The key of the secret to select from. Must be a valid secret key.\n";
            type = types.str;
          };
          "name" = mkOption {
            description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).\n";
            type = types.str;
          };
        };

        config = { };

      };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3CompatibleAwsCredentialsSecretKeySelectorsCaCertificate" =
      {

        options = {
          "key" = mkOption {
            description = "The key of the secret to select from. Must be a valid secret key.\n";
            type = types.str;
          };
          "name" = mkOption {
            description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).\n";
            type = types.str;
          };
        };

        config = { };

      };
    "stackgres.io.v1.SGBackupStatusSgBackupConfigStorageS3CompatibleAwsCredentialsSecretKeySelectorsSecretAccessKey" =
      {

        options = {
          "key" = mkOption {
            description = "The key of the secret to select from. Must be a valid secret key.\n";
            type = types.str;
          };
          "name" = mkOption {
            description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).\n";
            type = types.str;
          };
        };

        config = { };

      };
    "stackgres.io.v1.SGBackupStatusVolumeSnapshot" = {

      options = {
        "backupLabel" = mkOption {
          description = "The content of `backup_label` column returned by `pg_backup_stop` encoded in Base64\n";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The volume snapshot used to store this backup.\n";
          type = (types.nullOr types.str);
        };
        "tablespaceMap" = mkOption {
          description = "The content of `tablespace_map` column returned by `pg_backup_stop` encoded in Base64\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "backupLabel" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "tablespaceMap" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfig" = {

      options = {
        "apiVersion" = mkOption {
          description = "\nAPIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources\n";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "\nKind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds\n";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec defines the desired state of SGConfig";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpec"));
        };
        "status" = mkOption {
          description = "Status defines the observed state of SGConfig";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpec" = {

      options = {
        "adminui" = mkOption {
          description = "Section to configure Web Console container";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecAdminui"));
        };
        "allowImpersonationForRestApi" = mkOption {
          description = "When set to `true` the cluster role for impersonation will be created even if `disableClusterRole` is set to `true`.\n\nIt is `false` by default.\n\n> This value can only be set in operator helm chart.\n";
          type = (types.nullOr types.bool);
        };
        "allowedNamespaceLabelSelector" = mkOption {
          description = "Section to configure namespaces that the operator is allowed to use. If allowedNamespaces is defined it will be used instead. If empty all namespaces will be allowed (default).\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#labelselector-v1-meta\n\n> This value can only be set in operator helm chart.\n";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "allowedNamespaces" = mkOption {
          description = "Section to configure allowed namespaces that the operator is allowed to use. If empty all namespaces will be allowed (default).\n\n> This value can only be set in operator helm chart or with the environment variable `ALLOWED_NAMESPACES`.\n>   It is set by OLM when [scoping the operator](https://olm.operatorframework.io/docs/advanced-tasks/operator-scoping-with-operatorgroups/).\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "authentication" = mkOption {
          description = "Section to configure Web Console authentication";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecAuthentication"));
        };
        "cert" = mkOption {
          description = "Section to configure the Operator, REST API and Web Console certificates and JWT RSA key-pair.";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecCert"));
        };
        "collector" = mkOption {
          description = "Section to configure OpenTelemetry Collector\n\nBy default a single instance of OpenTelemetry Collector will receive metrics\n from all monitored Pods and will then exports those metrics to\n a configured target (by default will expose a Prometheus exporter).\n\nSee receivers section to scale this architecture to a set of OpenTelemetry Collectors.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecCollector"));
        };
        "containerRegistry" = mkOption {
          description = "The container registry host (and port) where the images will be pulled from.\n\n> This value can only be set in operator helm chart or with the environment variable `SG_CONTAINER_REGISTRY`.\n";
          type = (types.nullOr types.str);
        };
        "deploy" = mkOption {
          description = "Section to configure deployment aspects.";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecDeploy"));
        };
        "developer" = mkOption {
          description = "Section to configure developer options.\n\nFollowing options are for developers only, but can also be useful in some cases ;)\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecDeveloper"));
        };
        "disableClusterRole" = mkOption {
          description = "When set to `true` the creation of the operator ClusterRole and ClusterRoleBinding is disabled.\n Also, when `true`, some features that rely on unnamespaced resources premissions will be disabled:\n\n* Creation and upgrade of CustomResourceDefinitions\n* Set CA bundle for Webhooks\n* Check existence of CustomResourceDefinition when listing custom resources\n* Validation of StorageClass\n* REST API endpoint `can-i/{verb}/{resource}` and `can-i` will always return the full list of permissions for any resource and verb since they rely on creation of subjectaccessreviews unnamespaced resource that requires a cluster role.\n* Other REST API endpoints will not work since they rely on impersonation that requires a cluster role.\n  This point in particular breaks the Web Console completely. You may still enable this specific cluster role with `.allowImpersonationForRestApi`.\n  If you do not need the Web Console you may still disable it completely by setting `.deploy.restapi` to `false`.\n\nWhen set to `true` and `allowedNamespaces` is not set or is empty then `allowedNamespaces` will be considered set and containing only the namespace of the operator.\n\nIt is `false` by default.\n\n> This value can only be set in operator helm chart.\n";
          type = (types.nullOr types.bool);
        };
        "disableCrdsAndWebhooksUpdate" = mkOption {
          description = "When set to `true` the cluster role to update or patch CRDs will be disabled.\n\nIt is `false` by default.\n\n> This value can only be set in operator helm chart.\n";
          type = (types.nullOr types.bool);
        };
        "extensions" = mkOption {
          description = "Section to configure extensions";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecExtensions"));
        };
        "grafana" = mkOption {
          description = "Section to configure Grafana integration";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecGrafana"));
        };
        "imagePullPolicy" = mkOption {
          description = "Image pull policy used for images loaded by the Operator";
          type = (types.nullOr types.str);
        };
        "imagePullSecrets" = mkOption {
          description = "The list of references to secrets in the same namespace where a ServiceAccount is created by the operator to use for pulling any images in pods that reference such ServiceAccount. ImagePullSecrets are distinct from Secrets because Secrets can be mounted in the pod, but ImagePullSecrets are only accessed by the kubelet. More info: https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod\n";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "stackgres.io.v1.SGConfigSpecImagePullSecrets" "name" [ ]
            )
          );
          apply = attrsToList;
        };
        "jobs" = mkOption {
          description = "Section to configure Operator Installation Jobs";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecJobs"));
        };
        "operator" = mkOption {
          description = "Section to configure Operator Pod";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecOperator"));
        };
        "prometheus" = mkOption {
          description = "**Deprecated** this section has been replaced by `.spec.collector.prometheusOperator`.\n\nSection to configure Prometheus integration.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecPrometheus"));
        };
        "rbac" = mkOption {
          description = "Section to configure RBAC for Web Console admin user";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecRbac"));
        };
        "restapi" = mkOption {
          description = "Section to configure REST API Pod";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecRestapi"));
        };
        "serviceAccount" = mkOption {
          description = "Section to configure Operator Installation ServiceAccount";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecServiceAccount"));
        };
        "sgConfigNamespace" = mkOption {
          description = "When set will indicate the namespace where the SGConfig used by the operator will be created.\n\nBy default the SGConfig will be created in the same namespace as the operator.\n\n> This value can only be set in operator helm chart.\n";
          type = (types.nullOr types.str);
        };
        "shardingSphere" = mkOption {
          description = "Section to configure integration with ShardingSphere operator";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecShardingSphere"));
        };
      };

      config = {
        "adminui" = mkOverride 1002 null;
        "allowImpersonationForRestApi" = mkOverride 1002 null;
        "allowedNamespaceLabelSelector" = mkOverride 1002 null;
        "allowedNamespaces" = mkOverride 1002 null;
        "authentication" = mkOverride 1002 null;
        "cert" = mkOverride 1002 null;
        "collector" = mkOverride 1002 null;
        "containerRegistry" = mkOverride 1002 null;
        "deploy" = mkOverride 1002 null;
        "developer" = mkOverride 1002 null;
        "disableClusterRole" = mkOverride 1002 null;
        "disableCrdsAndWebhooksUpdate" = mkOverride 1002 null;
        "extensions" = mkOverride 1002 null;
        "grafana" = mkOverride 1002 null;
        "imagePullPolicy" = mkOverride 1002 null;
        "imagePullSecrets" = mkOverride 1002 null;
        "jobs" = mkOverride 1002 null;
        "operator" = mkOverride 1002 null;
        "prometheus" = mkOverride 1002 null;
        "rbac" = mkOverride 1002 null;
        "restapi" = mkOverride 1002 null;
        "serviceAccount" = mkOverride 1002 null;
        "sgConfigNamespace" = mkOverride 1002 null;
        "shardingSphere" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecAdminui" = {

      options = {
        "image" = mkOption {
          description = "Section to configure Web Console image";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecAdminuiImage"));
        };
        "resources" = mkOption {
          description = "Web Console resources. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#resourcerequirements-v1-core";
          type = (types.nullOr types.attrs);
        };
        "service" = mkOption {
          description = "Section to configure Web Console service.";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecAdminuiService"));
        };
      };

      config = {
        "image" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
        "service" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecAdminuiImage" = {

      options = {
        "name" = mkOption {
          description = "Web Console image name";
          type = (types.nullOr types.str);
        };
        "pullPolicy" = mkOption {
          description = "Web Console image pull policy";
          type = (types.nullOr types.str);
        };
        "tag" = mkOption {
          description = "Web Console image tag";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "pullPolicy" = mkOverride 1002 null;
        "tag" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecAdminuiService" = {

      options = {
        "exposeHTTP" = mkOption {
          description = "When set to `true` the HTTP port will be exposed in the Web Console Service";
          type = (types.nullOr types.bool);
        };
        "loadBalancerIP" = mkOption {
          description = "LoadBalancer will get created with the IP specified in\nthis field. This feature depends on whether the underlying cloud-provider supports specifying\nthe loadBalancerIP when a load balancer is created. This field will be ignored if the\ncloud-provider does not support the feature.\n";
          type = (types.nullOr types.str);
        };
        "loadBalancerSourceRanges" = mkOption {
          description = "If specified and supported by the platform,\nthis will restrict traffic through the cloud-provider load-balancer will be restricted to the\nspecified client IPs. This field will be ignored if the cloud-provider does not support the\nfeature.\nMore info: https://kubernetes.io/docs/tasks/access-application-cluster/configure-cloud-provider-firewall/\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "nodePort" = mkOption {
          description = "The HTTPS port used to expose the Service on Kubernetes nodes";
          type = (types.nullOr types.int);
        };
        "nodePortHTTP" = mkOption {
          description = "The HTTP port used to expose the Service on Kubernetes nodes";
          type = (types.nullOr types.int);
        };
        "type" = mkOption {
          description = "The type used for the service of the UI:\n* Set to LoadBalancer to create a load balancer (if supported by the kubernetes cluster)\n  to allow connect from Internet to the UI. Note that enabling this feature will probably incurr in\n  some fee that depend on the host of the kubernetes cluster (for example this is true for EKS, GKE\n  and AKS).\n* Set to NodePort to expose admin UI from kubernetes nodes.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "exposeHTTP" = mkOverride 1002 null;
        "loadBalancerIP" = mkOverride 1002 null;
        "loadBalancerSourceRanges" = mkOverride 1002 null;
        "nodePort" = mkOverride 1002 null;
        "nodePortHTTP" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecAuthentication" = {

      options = {
        "createAdminSecret" = mkOption {
          description = "When `true` will create the secret used to store the admin user credentials to access the UI.\n";
          type = (types.nullOr types.bool);
        };
        "oidc" = mkOption {
          description = "Section to configure Web Console OIDC authentication";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecAuthenticationOidc"));
        };
        "password" = mkOption {
          description = "The admin password that will be created for the Web Console.\n\nIf not specified a random password will be generated.\n";
          type = (types.nullOr types.str);
        };
        "secretRef" = mkOption {
          description = "Allow to specify a reference to a Secret with the admin user credentials for the Web Console.\n\nIn order to assign properly permissions. Make sure the `user` field match the value of the `k8sUsername` key in the referenced Secret.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecAuthenticationSecretRef"));
        };
        "type" = mkOption {
          description = "Specify the authentication mechanism to use. By default is `jwt`, see https://stackgres.io/doc/latest/api/rbac#local-secret-mechanism.\n If set to `oidc` then see https://stackgres.io/doc/latest/api/rbac/#openid-connect-provider-mechanism.\n";
          type = (types.nullOr types.str);
        };
        "user" = mkOption {
          description = "The admin username that will be created for the Web Console\n\nOperator bundle installation can not change the default value of this field.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "createAdminSecret" = mkOverride 1002 null;
        "oidc" = mkOverride 1002 null;
        "password" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecAuthenticationOidc" = {

      options = {
        "authServerUrl" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "clientId" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "clientIdSecretRef" = mkOption {
          description = "";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecAuthenticationOidcClientIdSecretRef")
          );
        };
        "credentialsSecret" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "credentialsSecretSecretRef" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGConfigSpecAuthenticationOidcCredentialsSecretSecretRef"
            )
          );
        };
        "tlsVerification" = mkOption {
          description = "Can be one of `required`, `certificate-validation` or `none`";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "authServerUrl" = mkOverride 1002 null;
        "clientId" = mkOverride 1002 null;
        "clientIdSecretRef" = mkOverride 1002 null;
        "credentialsSecret" = mkOverride 1002 null;
        "credentialsSecretSecretRef" = mkOverride 1002 null;
        "tlsVerification" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecAuthenticationOidcClientIdSecretRef" = {

      options = {
        "key" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecAuthenticationOidcCredentialsSecretSecretRef" = {

      options = {
        "key" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecAuthenticationSecretRef" = {

      options = {
        "name" = mkOption {
          description = "The name of the Secret.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecCert" = {

      options = {
        "autoapprove" = mkOption {
          description = "If set to `true` the CertificateSigningRequest used to generate the certificate used by\n Webhooks will be approved by the Operator Installation Job.\n";
          type = (types.nullOr types.bool);
        };
        "certDuration" = mkOption {
          description = "The duration in days of the generated certificate for the Operator after which it will expire and be regenerated.\nIf not specified it will be set to 730 (2 years) by default.\n";
          type = (types.nullOr types.int);
        };
        "certManager" = mkOption {
          description = "Section to configure cert-manager integration to generate Operator certificates";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecCertCertManager"));
        };
        "collectorCertDuration" = mkOption {
          description = "The duration in days of the generated certificate for the OpenTelemetry Collector after which it will expire and be regenerated.\nIf not specified it will be set to 730 (2 years) by default.\n";
          type = (types.nullOr types.int);
        };
        "collectorSecretName" = mkOption {
          description = "The Secret name with the OpenTelemetry Collector certificate\n of type kubernetes.io/tls. See https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets\n";
          type = (types.nullOr types.str);
        };
        "createForCollector" = mkOption {
          description = "When set to `true` the OpenTelemetry Collector certificate will be created.";
          type = (types.nullOr types.bool);
        };
        "createForOperator" = mkOption {
          description = "When set to `true` the Operator certificate will be created.";
          type = (types.nullOr types.bool);
        };
        "createForWebApi" = mkOption {
          description = "When set to `true` the Web Console / REST API certificate will be created.";
          type = (types.nullOr types.bool);
        };
        "regenerateCert" = mkOption {
          description = "When set to `true` the Operator certificates will be regenerated if `createForOperator` is set to `true`, and the certificate is expired or invalid.\n";
          type = (types.nullOr types.bool);
        };
        "regenerateCollectorCert" = mkOption {
          description = "When set to `true` the OpenTelemetry Collector certificates will be regenerated if `createForCollector` is set to `true`, and the certificate is expired or invalid.\n";
          type = (types.nullOr types.bool);
        };
        "regenerateWebCert" = mkOption {
          description = "When set to `true` the Web Console / REST API certificates will be regenerated if `createForWebApi` is set to `true`, and the certificate is expired or invalid.\n";
          type = (types.nullOr types.bool);
        };
        "regenerateWebRsa" = mkOption {
          description = "When set to `true` the Web Console / REST API RSA key pair will be regenerated if `createForWebApi` is set to `true`, and the certificate is expired or invalid.\n";
          type = (types.nullOr types.bool);
        };
        "secretName" = mkOption {
          description = "The Secret name with the Operator Webhooks certificate issued by the Kubernetes cluster CA\n of type kubernetes.io/tls. See https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets\n";
          type = (types.nullOr types.str);
        };
        "webCertDuration" = mkOption {
          description = "The duration in days of the generated certificate for the Web Console / REST API after which it will expire and be regenerated.\nIf not specified it will be set to 730 (2 years) by default.\n";
          type = (types.nullOr types.int);
        };
        "webRsaDuration" = mkOption {
          description = "The duration in days of the generated RSA key pair for the Web Console / REST API after which it will expire and be regenerated.\nIf not specified it will be set to 730 (2 years) by default.\n";
          type = (types.nullOr types.int);
        };
        "webSecretName" = mkOption {
          description = "The Secret name with the Web Console / REST API certificate\n of type kubernetes.io/tls. See https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "autoapprove" = mkOverride 1002 null;
        "certDuration" = mkOverride 1002 null;
        "certManager" = mkOverride 1002 null;
        "collectorCertDuration" = mkOverride 1002 null;
        "collectorSecretName" = mkOverride 1002 null;
        "createForCollector" = mkOverride 1002 null;
        "createForOperator" = mkOverride 1002 null;
        "createForWebApi" = mkOverride 1002 null;
        "regenerateCert" = mkOverride 1002 null;
        "regenerateCollectorCert" = mkOverride 1002 null;
        "regenerateWebCert" = mkOverride 1002 null;
        "regenerateWebRsa" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
        "webCertDuration" = mkOverride 1002 null;
        "webRsaDuration" = mkOverride 1002 null;
        "webSecretName" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecCertCertManager" = {

      options = {
        "autoConfigure" = mkOption {
          description = "When set to `true` then Issuer and Certificate for Operator, Web Console / REST API and OpenTelemetry Collector\n Pods will be generated\n";
          type = (types.nullOr types.bool);
        };
        "duration" = mkOption {
          description = "The requested duration (i.e. lifetime) of the Certificates. See https://cert-manager.io/docs/reference/api-docs/#cert-manager.io%2fv1";
          type = (types.nullOr types.str);
        };
        "encoding" = mkOption {
          description = "The private key cryptography standards (PKCS) encoding for this certificate’s private key to be encoded in. See https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.CertificatePrivateKey";
          type = (types.nullOr types.str);
        };
        "renewBefore" = mkOption {
          description = "How long before the currently issued certificate’s expiry cert-manager should renew the certificate. See https://cert-manager.io/docs/reference/api-docs/#cert-manager.io%2fv1";
          type = (types.nullOr types.str);
        };
        "size" = mkOption {
          description = "Size is the key bit size of the corresponding private key for this certificate. See https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.CertificatePrivateKey";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "autoConfigure" = mkOverride 1002 null;
        "duration" = mkOverride 1002 null;
        "encoding" = mkOverride 1002 null;
        "renewBefore" = mkOverride 1002 null;
        "size" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecCollector" = {

      options = {
        "affinity" = mkOption {
          description = "OpenTelemetry Collector Pod affinity. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#affinity-v1-core";
          type = (types.nullOr types.attrs);
        };
        "annotations" = mkOption {
          description = "OpenTelemetry Collector Pod annotations";
          type = (types.nullOr types.attrs);
        };
        "config" = mkOption {
          description = "Section to configure OpenTelemetry Collector Configuration. See https://opentelemetry.io/docs/collector/configuration";
          type = (types.nullOr types.attrs);
        };
        "name" = mkOption {
          description = "OpenTelemetry Collector Deploymnet/Deamonset base name";
          type = (types.nullOr types.str);
        };
        "nodeSelector" = mkOption {
          description = "OpenTelemetry Collector Pod node selector";
          type = (types.nullOr types.attrs);
        };
        "ports" = mkOption {
          description = "Section to configure OpenTelemetry Collector ports. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#containerport-v1-core";
          type = (types.nullOr (types.listOf types.attrs));
        };
        "prometheusOperator" = mkOption {
          description = "Section to configure OpenTelemetry Collector integration with Prometheus Operator.";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecCollectorPrometheusOperator"));
        };
        "receivers" = mkOption {
          description = "This section allow to configure a variable number of OpenTelemetry Collector\n receivers (by default equals to the number of Pod with metrics enabled)\n that will scrape the metrics separately and send them to a defined number\n of OpenTelemetry Collector exporters (by default 1) that exports those metrics\n to one or more configured targets (by default will expose a Prometheus exporter).\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecCollectorReceivers"));
        };
        "resources" = mkOption {
          description = "OpenTelemetry Collector Pod resources. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#resourcerequirements-v1-core";
          type = (types.nullOr types.attrs);
        };
        "service" = mkOption {
          description = "Section to configure OpenTelemetry Collector Service";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecCollectorService"));
        };
        "serviceAccount" = mkOption {
          description = "Section to configure OpenTelemetry Collector ServiceAccount";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecCollectorServiceAccount"));
        };
        "tolerations" = mkOption {
          description = "OpenTelemetry Collector Pod tolerations. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#toleration-v1-core";
          type = (types.nullOr (types.listOf types.attrs));
        };
        "volumeMounts" = mkOption {
          description = "Section to configure OpenTelemetry Collector Volume Mounts. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#volumemount-v1-core";
          type = (types.nullOr (types.listOf types.attrs));
        };
        "volumes" = mkOption {
          description = "Section to configure OpenTelemetry Collector Volumes. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#volume-v1-core";
          type = (types.nullOr (types.listOf types.attrs));
        };
      };

      config = {
        "affinity" = mkOverride 1002 null;
        "annotations" = mkOverride 1002 null;
        "config" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "nodeSelector" = mkOverride 1002 null;
        "ports" = mkOverride 1002 null;
        "prometheusOperator" = mkOverride 1002 null;
        "receivers" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
        "service" = mkOverride 1002 null;
        "serviceAccount" = mkOverride 1002 null;
        "tolerations" = mkOverride 1002 null;
        "volumeMounts" = mkOverride 1002 null;
        "volumes" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecCollectorPrometheusOperator" = {

      options = {
        "allowDiscovery" = mkOption {
          description = "If set to false or monitors is set automatic bind to Prometheus\n created using the [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator) will be disabled.\n\nIf disabled the cluster will not be binded to Prometheus automatically and will require manual configuration.\n\nWill be ignored if monitors is set.\n";
          type = (types.nullOr types.bool);
        };
        "monitors" = mkOption {
          description = "Optional section to configure PodMonitors for specific Prometheus instances\n\n*WARNING*: resources created by this integration that does set\n the metadata namespace to the same as the operator will not\n be removed when removing the helm chart. Changing the namespace\n may require configure the Prometheus CR properly in order to\n discover PodMonitor in such namespace.\n";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "stackgres.io.v1.SGConfigSpecCollectorPrometheusOperatorMonitors"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
      };

      config = {
        "allowDiscovery" = mkOverride 1002 null;
        "monitors" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecCollectorPrometheusOperatorMonitors" = {

      options = {
        "metadata" = mkOption {
          description = "Section to overwrite some PodMonitor metadata";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecCollectorPrometheusOperatorMonitorsMetadata")
          );
        };
        "name" = mkOption {
          description = "The name of the Prometheus resource that will scrape from the collector Pod pointing by default to the prometheus exporter";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Prometheus resource that will scrape from the collector Pod pointing by default to the prometheus exporter";
          type = (types.nullOr types.str);
        };
        "spec" = mkOption {
          description = "The PodMonitor spec that will be overwritten by the operator. See https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#monitoring.coreos.com/v1.PodMonitorSpec";
          type = (types.nullOr types.attrs);
        };
      };

      config = {
        "metadata" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecCollectorPrometheusOperatorMonitorsMetadata" = {

      options = {
        "annotations" = mkOption {
          description = "The labels to set for the PodMonitor";
          type = (types.nullOr types.attrs);
        };
        "labels" = mkOption {
          description = "The labels to set for the PodMonitor";
          type = (types.nullOr types.attrs);
        };
        "name" = mkOption {
          description = "The name of the PodMonitor";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the PodMonitor. Changing the namespace may require configure the Prometheus CR properly in order to discover PodMonitor in such namespace.";
          type = (types.nullOr types.str);
        };
        "ownerReferences" = mkOption {
          description = "The ownerReferences to set for the PodMonitor in order to be garbage collected by the specified object.";
          type = (types.nullOr (types.listOf types.attrs));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "ownerReferences" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecCollectorReceivers" = {

      options = {
        "deployments" = mkOption {
          description = "A set of separate Deployments of 1 instance each that allow to set the OpenTelemetry Collectors receivers to a specified number of instances.\n\nWhen not set the number of Deployment of OpenTelemetry Collectors receivers will match the number of instances of all the existing SGClusters\n that has the field `.spec.configurations.observability.enableMetrics` set to `true`. Also, when not set, each Deployment will include a pod\n affinity rule matching any of the SGClusters Pods set defined below. This will allow to create an OpenTelemetry Collector receiver instance\n dedicated to each SGCluster Pod running in the same Node.\n\nEach Deployment will use a configuration for the OpenTelemetry Collector that will scrape from a set of SGClusters Pods that has the field\n `.spec.configurations.observability.enableMetrics` set to `true`. The set of Pods of each of those OpenTelemetry Collector configuration\n will be a partition of the list of SGClusters Pods that has the field `.spec.configurations.observability.enableMetrics` set to `true`\n ordered by the field `Pod.metadata.creationTimestamp` (from the oldest to the newest) and ordered crescently alphabetically by the fields\n `Pod.metadata.namespace` and `Pod.metadata.name`.\n\nIf is possible to override (even partially) the list of SGCluster Pods using the `sgClusters` section.\n";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "stackgres.io.v1.SGConfigSpecCollectorReceiversDeployments")
            )
          );
        };
        "enabled" = mkOption {
          description = "When set to `true` it enables the creation of a set of OpenTelemetry Collectors receivers\n that will be scraping from the SGCluster Pods and allow to scale the observability\n architecture and a set of OpenTelemetry Collectors exporters that exports those metrics\n to one or more configured targets.\n";
          type = (types.nullOr types.bool);
        };
        "exporters" = mkOption {
          description = "When receivers are enabled indicates the number of OpenTelemetry Collectors exporters that\n exports metrics to one or more configured targets.\n";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "deployments" = mkOverride 1002 null;
        "enabled" = mkOverride 1002 null;
        "exporters" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecCollectorReceiversDeployments" = {

      options = {
        "affinity" = mkOption {
          description = "OpenTelemetry Collector Pod affinity. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#affinity-v1-core";
          type = (types.nullOr types.attrs);
        };
        "annotations" = mkOption {
          description = "OpenTelemetry Collector Pod annotations";
          type = (types.nullOr types.attrs);
        };
        "nodeSelector" = mkOption {
          description = "OpenTelemetry Collector Pod node selector";
          type = (types.nullOr types.attrs);
        };
        "resources" = mkOption {
          description = "OpenTelemetry Collector Pod resources. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#resourcerequirements-v1-core";
          type = (types.nullOr types.attrs);
        };
        "sgClusters" = mkOption {
          description = "List of SGCluster Pods to scrape from this Deployment's Pod that will be included to the OpenTelemetry Collector\n configuration alongside the SGCluster Pods assigned as described in `SGConfig.spec.collector.receivers.deployments`.\n";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "stackgres.io.v1.SGConfigSpecCollectorReceiversDeploymentsSgClusters"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "tolerations" = mkOption {
          description = "OpenTelemetry Collector Pod tolerations. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#toleration-v1-core";
          type = (types.nullOr (types.listOf types.attrs));
        };
      };

      config = {
        "affinity" = mkOverride 1002 null;
        "annotations" = mkOverride 1002 null;
        "nodeSelector" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
        "sgClusters" = mkOverride 1002 null;
        "tolerations" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecCollectorReceiversDeploymentsSgClusters" = {

      options = {
        "indexes" = mkOption {
          description = "The indexes of the SGCluster's Pods that will be included to the OpenTelemetry Collector configuration alongside\n the SGCluster Pods assigned as described in `SGConfig.spec.collector.receivers.deployments`.\n\nIf not specified all the SGCluster's Pods will be included.\n";
          type = (types.nullOr (types.listOf types.int));
        };
        "name" = mkOption {
          description = "The name of the SGCluster";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the SGCluster";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "indexes" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecCollectorService" = {

      options = {
        "annotations" = mkOption {
          description = "OpenTelemetry Collector Service annotations";
          type = (types.nullOr types.attrs);
        };
        "spec" = mkOption {
          description = "Section to configure OpenTelemetry Collector Service specs. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#servicespec-v1-core";
          type = (types.nullOr types.attrs);
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecCollectorServiceAccount" = {

      options = {
        "annotations" = mkOption {
          description = "OpenTelemetry Collector ServiceAccount annotations";
          type = (types.nullOr types.attrs);
        };
        "repoCredentials" = mkOption {
          description = "Repositories credentials Secret names";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "repoCredentials" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecDeploy" = {

      options = {
        "collector" = mkOption {
          description = "When set to `true` the OpenTelemetry Collector will be deployed.";
          type = (types.nullOr types.bool);
        };
        "operator" = mkOption {
          description = "When set to `true` the Operator will be deployed.";
          type = (types.nullOr types.bool);
        };
        "restapi" = mkOption {
          description = "When set to `true` the Web Console / REST API will be deployed.";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "collector" = mkOverride 1002 null;
        "operator" = mkOverride 1002 null;
        "restapi" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecDeveloper" = {

      options = {
        "allowPullExtensionsFromImageRepository" = mkOption {
          description = "If set to `true` and `extensions.cache.enabled` is also `true`\n it will try to download extensions from images (experimental)\n";
          type = (types.nullOr types.bool);
        };
        "disableArbitraryUser" = mkOption {
          description = "It set to `true` disable arbitrary user that is set for OpenShift clusters\n";
          type = (types.nullOr types.bool);
        };
        "enableJvmDebug" = mkOption {
          description = "Only work with JVM version and allow connect\n on port 8000 of operator Pod with jdb or similar\n";
          type = (types.nullOr types.bool);
        };
        "enableJvmDebugSuspend" = mkOption {
          description = "Only work with JVM version and if `enableJvmDebug` is `true`\n suspend the JVM until a debugger session is started\n";
          type = (types.nullOr types.bool);
        };
        "externalOperatorIp" = mkOption {
          description = "Set the external Operator IP";
          type = (types.nullOr types.str);
        };
        "externalOperatorPort" = mkOption {
          description = "Set the external Operator port";
          type = (types.nullOr types.int);
        };
        "externalRestApiIp" = mkOption {
          description = "Set the external REST API IP";
          type = (types.nullOr types.str);
        };
        "externalRestApiPort" = mkOption {
          description = "Set the external REST API port";
          type = (types.nullOr types.int);
        };
        "logLevel" = mkOption {
          description = "Set `quarkus.log.level`. See https://quarkus.io/guides/logging#root-logger-configuration";
          type = (types.nullOr types.str);
        };
        "patches" = mkOption {
          description = "Section to define patches for some StackGres Pods\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecDeveloperPatches"));
        };
        "showDebug" = mkOption {
          description = "If set to `true` add extra debug to any script controlled by the reconciliation cycle of the operator configuration";
          type = (types.nullOr types.bool);
        };
        "showStackTraces" = mkOption {
          description = "Set `quarkus.log.console.format` to `%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p [%c{4.}] (%t) %s%e%n`. See https://quarkus.io/guides/logging#logging-format";
          type = (types.nullOr types.bool);
        };
        "useJvmImages" = mkOption {
          description = "The operator will use JVM version of the images\n";
          type = (types.nullOr types.bool);
        };
        "version" = mkOption {
          description = "Set the operator version (used for testing)";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "allowPullExtensionsFromImageRepository" = mkOverride 1002 null;
        "disableArbitraryUser" = mkOverride 1002 null;
        "enableJvmDebug" = mkOverride 1002 null;
        "enableJvmDebugSuspend" = mkOverride 1002 null;
        "externalOperatorIp" = mkOverride 1002 null;
        "externalOperatorPort" = mkOverride 1002 null;
        "externalRestApiIp" = mkOverride 1002 null;
        "externalRestApiPort" = mkOverride 1002 null;
        "logLevel" = mkOverride 1002 null;
        "patches" = mkOverride 1002 null;
        "showDebug" = mkOverride 1002 null;
        "showStackTraces" = mkOverride 1002 null;
        "useJvmImages" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecDeveloperPatches" = {

      options = {
        "adminui" = mkOption {
          description = "Section to define volumes to be used by the adminui container\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecDeveloperPatchesAdminui"));
        };
        "clusterController" = mkOption {
          description = "Section to define volumes to be used by the cluster controller container\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecDeveloperPatchesClusterController"));
        };
        "jobs" = mkOption {
          description = "Section to define volumes to be used by the jobs container\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecDeveloperPatchesJobs"));
        };
        "operator" = mkOption {
          description = "Section to define volumes to be used by the operator container\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecDeveloperPatchesOperator"));
        };
        "restapi" = mkOption {
          description = "Section to define volumes to be used by the restapi container\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecDeveloperPatchesRestapi"));
        };
        "stream" = mkOption {
          description = "Section to define volumes to be used by the stream container\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecDeveloperPatchesStream"));
        };
      };

      config = {
        "adminui" = mkOverride 1002 null;
        "clusterController" = mkOverride 1002 null;
        "jobs" = mkOverride 1002 null;
        "operator" = mkOverride 1002 null;
        "restapi" = mkOverride 1002 null;
        "stream" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecDeveloperPatchesAdminui" = {

      options = {
        "volumeMounts" = mkOption {
          description = "Pod's container volume mounts. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#volumemount-v1-core";
          type = (types.nullOr (types.listOf types.attrs));
        };
        "volumes" = mkOption {
          description = "Pod volumes. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#volume-v1-core";
          type = (types.nullOr (types.listOf types.attrs));
        };
      };

      config = {
        "volumeMounts" = mkOverride 1002 null;
        "volumes" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecDeveloperPatchesClusterController" = {

      options = {
        "volumeMounts" = mkOption {
          description = "Pod's container volume mounts. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#volumemount-v1-core";
          type = (types.nullOr (types.listOf types.attrs));
        };
        "volumes" = mkOption {
          description = "Pod volumes. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#volume-v1-core";
          type = (types.nullOr (types.listOf types.attrs));
        };
      };

      config = {
        "volumeMounts" = mkOverride 1002 null;
        "volumes" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecDeveloperPatchesJobs" = {

      options = {
        "volumeMounts" = mkOption {
          description = "Pod's container volume mounts. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#volumemount-v1-core";
          type = (types.nullOr (types.listOf types.attrs));
        };
        "volumes" = mkOption {
          description = "Pod volumes. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#volume-v1-core";
          type = (types.nullOr (types.listOf types.attrs));
        };
      };

      config = {
        "volumeMounts" = mkOverride 1002 null;
        "volumes" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecDeveloperPatchesOperator" = {

      options = {
        "volumeMounts" = mkOption {
          description = "Pod's container volume mounts. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#volumemount-v1-core";
          type = (types.nullOr (types.listOf types.attrs));
        };
        "volumes" = mkOption {
          description = "Pod volumes. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#volume-v1-core";
          type = (types.nullOr (types.listOf types.attrs));
        };
      };

      config = {
        "volumeMounts" = mkOverride 1002 null;
        "volumes" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecDeveloperPatchesRestapi" = {

      options = {
        "volumeMounts" = mkOption {
          description = "Pod's container volume mounts. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#volumemount-v1-core";
          type = (types.nullOr (types.listOf types.attrs));
        };
        "volumes" = mkOption {
          description = "Pod volumes. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#volume-v1-core";
          type = (types.nullOr (types.listOf types.attrs));
        };
      };

      config = {
        "volumeMounts" = mkOverride 1002 null;
        "volumes" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecDeveloperPatchesStream" = {

      options = {
        "volumeMounts" = mkOption {
          description = "Pod's container volume mounts. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#volumemount-v1-core";
          type = (types.nullOr (types.listOf types.attrs));
        };
        "volumes" = mkOption {
          description = "Pod volumes. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#volume-v1-core";
          type = (types.nullOr (types.listOf types.attrs));
        };
      };

      config = {
        "volumeMounts" = mkOverride 1002 null;
        "volumes" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecExtensions" = {

      options = {
        "cache" = mkOption {
          description = "Section to configure extensions cache (experimental).\n\nThis feature is in beta and may cause failures, please use with caution and report any\n error to https://gitlab.com/ongresinc/stackgres/-/issues/new\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecExtensionsCache"));
        };
        "repositoryUrls" = mkOption {
          description = "A list of extensions repository URLs used to retrieve extensions\n\nTo set a proxy for extensions repository add parameter proxyUrl to the URL:\n    `https://extensions.stackgres.io/postgres/repository?proxyUrl=<proxy scheme>%3A%2F%2F<proxy host>[%3A<proxy port>]` (URL encoded)\n\nOther URL parameters are:\n\n* `skipHostnameVerification`: set it to `true` in order to use a server or a proxy with a self signed certificate\n* `retry`: set it to `<max retriex>[:<sleep before next retry>]` in order to retry a request on failure\n* `setHttpScheme`: set it to `true` in order to force using HTTP scheme\n";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "cache" = mkOverride 1002 null;
        "repositoryUrls" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecExtensionsCache" = {

      options = {
        "enabled" = mkOption {
          description = "When set to `true` enable the extensions cache.\n\nThis feature is in beta and may cause failures, please use with caution and report any\n error to https://gitlab.com/ongresinc/stackgres/-/issues/new\n";
          type = (types.nullOr types.bool);
        };
        "hostPath" = mkOption {
          description = "If set, will use a host path volume with the specified path for the extensions cache\n instead of a PersistentVolume\n";
          type = (types.nullOr types.str);
        };
        "persistentVolume" = mkOption {
          description = "Section to configure the extensions cache PersistentVolume";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecExtensionsCachePersistentVolume"));
        };
        "preloadedExtensions" = mkOption {
          description = "An array of extensions pattern used to pre-loaded estensions into the extensions cache";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "enabled" = mkOverride 1002 null;
        "hostPath" = mkOverride 1002 null;
        "persistentVolume" = mkOverride 1002 null;
        "preloadedExtensions" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecExtensionsCachePersistentVolume" = {

      options = {
        "size" = mkOption {
          description = "The PersistentVolume size for the extensions cache\n\nOnly use whole numbers (e.g. not 1e6) and K/Ki/M/Mi/G/Gi as units\n";
          type = (types.nullOr types.str);
        };
        "storageClass" = mkOption {
          description = "If defined set storage class\nIf set to \"-\" (equivalent to storageClass: \"\" in a PV spec) disables\n dynamic provisioning\nIf undefined (the default) or set to null, no storageClass spec is\n set, choosing the default provisioner.  (gp2 on AWS, standard on\n GKE, AWS & OpenStack)\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "size" = mkOverride 1002 null;
        "storageClass" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecGrafana" = {

      options = {
        "autoEmbed" = mkOption {
          description = "When set to `true` embed automatically Grafana into the Web Console by creating the\n StackGres dashboard and the read-only role used to read it from the Web Console \n";
          type = (types.nullOr types.bool);
        };
        "dashboardConfigMap" = mkOption {
          description = "The ConfigMap name with the dashboard JSON in the key `grafana-dashboard.json`\n that will be created in Grafana. If not set the default\n";
          type = (types.nullOr types.str);
        };
        "dashboardId" = mkOption {
          description = "The dashboard id that will be create in Grafana\n (see https://grafana.com/grafana/dashboards). By default 9628. (used to embed automatically\n Grafana)\n\nManual Steps:\n \nCreate grafana dashboard for postgres exporter and copy/paste share URL:\n- Grafana > Create > Import > Grafana.com Dashboard 9628\nCopy/paste grafana dashboard URL for postgres exporter:\n- Grafana > Dashboard > Manage > Select postgres exporter dashboard > Copy URL\n";
          type = (types.nullOr types.str);
        };
        "datasourceName" = mkOption {
          description = "The datasource name used to create the StackGres Dashboard into Grafana";
          type = (types.nullOr types.str);
        };
        "password" = mkOption {
          description = "The password to access Grafana. By default prom-operator (the default in for\n kube-prometheus-stack helm chart). (used to embed automatically Grafana)\n";
          type = (types.nullOr types.str);
        };
        "schema" = mkOption {
          description = "The schema to access Grafana. By default http. (used to embed manually and\n automatically grafana)\n";
          type = (types.nullOr types.str);
        };
        "secretName" = mkOption {
          description = "The name of secret with credentials to access Grafana. (used to embed\n automatically Grafana, alternative to use `user` and `password`)\n";
          type = (types.nullOr types.str);
        };
        "secretNamespace" = mkOption {
          description = "The namespace of secret with credentials to access Grafana. (used to\n embed automatically Grafana, alternative to use `user` and `password`)\n";
          type = (types.nullOr types.str);
        };
        "secretPasswordKey" = mkOption {
          description = "The key of secret with password used to access Grafana. (used to\n embed automatically Grafana, alternative to use `user` and `password`)\n";
          type = (types.nullOr types.str);
        };
        "secretUserKey" = mkOption {
          description = "The key of secret with username used to access Grafana. (used to embed\n automatically Grafana, alternative to use `user` and `password`)\n";
          type = (types.nullOr types.str);
        };
        "token" = mkOption {
          description = "The Grafana API token to access the PostgreSQL dashboard created\n in Grafana (used to embed manually Grafana)\n\nManual Steps:\n \nCreate and copy/paste grafana API token:\n- Grafana > Configuration > API Keys > Add API key (for viewer) > Copy key value\n";
          type = (types.nullOr types.str);
        };
        "url" = mkOption {
          description = "The URL of the PostgreSQL dashboard created in Grafana (used to embed manually\n Grafana)\n";
          type = (types.nullOr types.str);
        };
        "user" = mkOption {
          description = "The username to access Grafana. By default admin. (used to embed automatically\n Grafana)\n";
          type = (types.nullOr types.str);
        };
        "webHost" = mkOption {
          description = "The service host name to access grafana (used to embed manually and\n automatically Grafana). \nThe parameter value should point to the grafana service following the \n [DNS reference](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) `svc_name.namespace`\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "autoEmbed" = mkOverride 1002 null;
        "dashboardConfigMap" = mkOverride 1002 null;
        "dashboardId" = mkOverride 1002 null;
        "datasourceName" = mkOverride 1002 null;
        "password" = mkOverride 1002 null;
        "schema" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
        "secretNamespace" = mkOverride 1002 null;
        "secretPasswordKey" = mkOverride 1002 null;
        "secretUserKey" = mkOverride 1002 null;
        "token" = mkOverride 1002 null;
        "url" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
        "webHost" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecImagePullSecrets" = {

      options = {
        "name" = mkOption {
          description = "The name of the referenced Secret.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecJobs" = {

      options = {
        "affinity" = mkOption {
          description = "Operator Installation Jobs affinity. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#affinity-v1-core";
          type = (types.nullOr types.attrs);
        };
        "annotations" = mkOption {
          description = "Operator Installation Jobs annotations";
          type = (types.nullOr types.attrs);
        };
        "image" = mkOption {
          description = "Section to configure Operator Installation Jobs image";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecJobsImage"));
        };
        "nodeSelector" = mkOption {
          description = "Operator Installation Jobs node selector";
          type = (types.nullOr types.attrs);
        };
        "resources" = mkOption {
          description = "Operator Installation Jobs resources. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#resourcerequirements-v1-core";
          type = (types.nullOr types.attrs);
        };
        "serviceAccount" = mkOption {
          description = "Section to configure Jobs ServiceAccount";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecJobsServiceAccount"));
        };
        "tolerations" = mkOption {
          description = "Operator Installation Jobs tolerations. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#toleration-v1-core";
          type = (types.nullOr (types.listOf types.attrs));
        };
      };

      config = {
        "affinity" = mkOverride 1002 null;
        "annotations" = mkOverride 1002 null;
        "image" = mkOverride 1002 null;
        "nodeSelector" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
        "serviceAccount" = mkOverride 1002 null;
        "tolerations" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecJobsImage" = {

      options = {
        "name" = mkOption {
          description = "Operator Installation Jobs image name";
          type = (types.nullOr types.str);
        };
        "pullPolicy" = mkOption {
          description = "Operator Installation Jobs image pull policy";
          type = (types.nullOr types.str);
        };
        "tag" = mkOption {
          description = "Operator Installation Jobs image tag";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "pullPolicy" = mkOverride 1002 null;
        "tag" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecJobsServiceAccount" = {

      options = {
        "annotations" = mkOption {
          description = "Jobs ServiceAccount annotations";
          type = (types.nullOr types.attrs);
        };
        "repoCredentials" = mkOption {
          description = "Repositories credentials Secret names";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "repoCredentials" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecOperator" = {

      options = {
        "affinity" = mkOption {
          description = "Operator Pod affinity. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#affinity-v1-core\n\n> This value can only be set in operator helm chart.\n";
          type = (types.nullOr types.attrs);
        };
        "annotations" = mkOption {
          description = "Operator Pod annotations";
          type = (types.nullOr types.attrs);
        };
        "hostNetwork" = mkOption {
          description = "Host networking requested for this pod. Use the host's network namespace. If this option is set, the ports that will be used must be specified. Default to false.\n\n> This value can only be set in operator helm chart.\n";
          type = (types.nullOr types.bool);
        };
        "image" = mkOption {
          description = "Section to configure Operator image";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecOperatorImage"));
        };
        "internalHttpPort" = mkOption {
          description = "The port that the operator will use to listen for HTTP\n\n> This value can only be set in operator helm chart or with the environment variable `OPERATOR_HTTP_PORT`.\n";
          type = (types.nullOr types.int);
        };
        "internalHttpsPort" = mkOption {
          description = "The port that the operator will use to listen for HTTPS\n\n> This value can only be set in operator helm chart or with the environment variable `OPERATOR_HTTPS_PORT`.\n";
          type = (types.nullOr types.int);
        };
        "nodeSelector" = mkOption {
          description = "Operator Pod node selector\n\n> This value can only be set in operator helm chart.\n";
          type = (types.nullOr types.attrs);
        };
        "port" = mkOption {
          description = "The port that will be exposed by the operator Service for HTTPS\n\n> This value can only be set in operator helm chart.\n";
          type = (types.nullOr types.int);
        };
        "resources" = mkOption {
          description = "Operator Pod resources. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#resourcerequirements-v1-core\n\n> This value can only be set in operator helm chart.\n";
          type = (types.nullOr types.attrs);
        };
        "service" = mkOption {
          description = "Section to configure Operator Service";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecOperatorService"));
        };
        "serviceAccount" = mkOption {
          description = "Section to configure Operator ServiceAccount";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecOperatorServiceAccount"));
        };
        "tolerations" = mkOption {
          description = "Operator Pod tolerations. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#toleration-v1-core\n\n> This value can only be set in operator helm chart.\n";
          type = (types.nullOr (types.listOf types.attrs));
        };
      };

      config = {
        "affinity" = mkOverride 1002 null;
        "annotations" = mkOverride 1002 null;
        "hostNetwork" = mkOverride 1002 null;
        "image" = mkOverride 1002 null;
        "internalHttpPort" = mkOverride 1002 null;
        "internalHttpsPort" = mkOverride 1002 null;
        "nodeSelector" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
        "service" = mkOverride 1002 null;
        "serviceAccount" = mkOverride 1002 null;
        "tolerations" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecOperatorImage" = {

      options = {
        "name" = mkOption {
          description = "Operator image name\n\n> This value can only be set in operator helm chart.\n";
          type = (types.nullOr types.str);
        };
        "pullPolicy" = mkOption {
          description = "Operator image pull policy\n\n> This value can only be set in operator helm chart.\n";
          type = (types.nullOr types.str);
        };
        "tag" = mkOption {
          description = "Operator image tag\n\n> This value can only be set in operator helm chart.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "pullPolicy" = mkOverride 1002 null;
        "tag" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecOperatorService" = {

      options = {
        "annotations" = mkOption {
          description = "Section to configure Operator Service annotations\n\n> This value can only be set in operator helm chart.\n";
          type = (types.nullOr types.attrs);
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecOperatorServiceAccount" = {

      options = {
        "annotations" = mkOption {
          description = "Section to configure Operator ServiceAccount annotations\n\n> This value can only be set in operator helm chart.\n";
          type = (types.nullOr types.attrs);
        };
        "repoCredentials" = mkOption {
          description = "Repositories credentials Secret names\n\n> This value can only be set in operator helm chart.\n";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "repoCredentials" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecPrometheus" = {

      options = {
        "allowAutobind" = mkOption {
          description = "**Deprecated** this field has been replaced by `.spec.collector.prometheusOperator.allowDiscovery`.\n\nIf set to false disable automatic bind to Prometheus\n  created using the [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator).\nIf disabled the cluster will not be binded to Prometheus automatically and will require manual\n  intervention by the Kubernetes cluster administrator.\n";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "allowAutobind" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecRbac" = {

      options = {
        "create" = mkOption {
          description = "When set to `true` the admin user is assigned the `cluster-admin` ClusterRole by creating\n ClusterRoleBinding.\n";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "create" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecRestapi" = {

      options = {
        "affinity" = mkOption {
          description = "REST API Pod affinity. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#affinity-v1-core";
          type = (types.nullOr types.attrs);
        };
        "annotations" = mkOption {
          description = "REST API Pod annotations";
          type = (types.nullOr types.attrs);
        };
        "image" = mkOption {
          description = "Section to configure REST API image";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecRestapiImage"));
        };
        "name" = mkOption {
          description = "REST API Deployment name";
          type = (types.nullOr types.str);
        };
        "nodeSelector" = mkOption {
          description = "REST API Pod node selector";
          type = (types.nullOr types.attrs);
        };
        "resources" = mkOption {
          description = "REST API Pod resources. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#resourcerequirements-v1-core";
          type = (types.nullOr types.attrs);
        };
        "service" = mkOption {
          description = "Section to configure REST API Service";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecRestapiService"));
        };
        "serviceAccount" = mkOption {
          description = "Section to configure REST API ServiceAccount";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecRestapiServiceAccount"));
        };
        "tolerations" = mkOption {
          description = "REST API Pod tolerations. See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#toleration-v1-core";
          type = (types.nullOr (types.listOf types.attrs));
        };
      };

      config = {
        "affinity" = mkOverride 1002 null;
        "annotations" = mkOverride 1002 null;
        "image" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "nodeSelector" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
        "service" = mkOverride 1002 null;
        "serviceAccount" = mkOverride 1002 null;
        "tolerations" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecRestapiImage" = {

      options = {
        "name" = mkOption {
          description = "REST API image name";
          type = (types.nullOr types.str);
        };
        "pullPolicy" = mkOption {
          description = "REST API image pull policy";
          type = (types.nullOr types.str);
        };
        "tag" = mkOption {
          description = "REST API image tag";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "pullPolicy" = mkOverride 1002 null;
        "tag" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecRestapiService" = {

      options = {
        "annotations" = mkOption {
          description = "REST API Service annotations";
          type = (types.nullOr types.attrs);
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecRestapiServiceAccount" = {

      options = {
        "annotations" = mkOption {
          description = "REST API ServiceAccount annotations";
          type = (types.nullOr types.attrs);
        };
        "repoCredentials" = mkOption {
          description = "Repositories credentials Secret names";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "repoCredentials" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecServiceAccount" = {

      options = {
        "annotations" = mkOption {
          description = "Section to configure Installation ServiceAccount annotations";
          type = (types.nullOr types.attrs);
        };
        "create" = mkOption {
          description = "If `true` the Operator Installation ServiceAccount will be created\n\n> This value can only be set in operator helm chart.\n";
          type = (types.nullOr types.bool);
        };
        "repoCredentials" = mkOption {
          description = "Repositories credentials Secret names\n\n> This value can only be set in operator helm chart.\n";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "create" = mkOverride 1002 null;
        "repoCredentials" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecShardingSphere" = {

      options = {
        "serviceAccount" = mkOption {
          description = "Section to configure ServiceAccount used by ShardingSphere operator.\n\nYou may configure a specific value for a sharded cluster under section\n `SGShardedCluster.speccoordinator.configurations.shardingSphere.serviceAccount`.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigSpecShardingSphereServiceAccount"));
        };
      };

      config = {
        "serviceAccount" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigSpecShardingSphereServiceAccount" = {

      options = {
        "name" = mkOption {
          description = "The name of the ServiceAccount used by ShardingSphere operator";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "The namespace of the ServiceAccount used by ShardingSphere operator";
          type = types.str;
        };
      };

      config = { };

    };
    "stackgres.io.v1.SGConfigStatus" = {

      options = {
        "conditions" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "stackgres.io.v1.SGConfigStatusConditions")));
        };
        "existingCrUpdatedToVersion" = mkOption {
          description = "Indicate the version to which existing CRs have been updated to";
          type = (types.nullOr types.str);
        };
        "grafana" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGConfigStatusGrafana"));
        };
        "removeOldOperatorBundleResources" = mkOption {
          description = "Indicate when the old operator bundle resources has been removed";
          type = (types.nullOr types.bool);
        };
        "version" = mkOption {
          description = "Latest version of the operator used to check for updates";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "existingCrUpdatedToVersion" = mkOverride 1002 null;
        "grafana" = mkOverride 1002 null;
        "removeOldOperatorBundleResources" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "Last time the condition transitioned from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "A human readable message indicating details about the transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "The reason for the condition's last transition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "Status of the condition, one of True, False, Unknown.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "Type of deployment condition.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGConfigStatusGrafana" = {

      options = {
        "configHash" = mkOption {
          description = "Grafana configuration hash";
          type = (types.nullOr types.str);
        };
        "token" = mkOption {
          description = "Grafana Token that allow to access dashboards";
          type = (types.nullOr types.str);
        };
        "urls" = mkOption {
          description = "Grafana URLs to StackGres dashboards";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "configHash" = mkOverride 1002 null;
        "token" = mkOverride 1002 null;
        "urls" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOps" = {

      options = {
        "apiVersion" = mkOption {
          description = "\nAPIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources\n";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "\nKind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds\n";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "";
          type = (submoduleOf "stackgres.io.v1.SGDbOpsSpec");
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpec" = {

      options = {
        "benchmark" = mkOption {
          description = "Configuration of the benchmark\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsSpecBenchmark"));
        };
        "majorVersionUpgrade" = mkOption {
          description = "Configuration of major version upgrade (see also [`pg_upgrade`](https://www.postgresql.org/docs/current/pgupgrade.html) command)\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsSpecMajorVersionUpgrade"));
        };
        "maxRetries" = mkOption {
          description = "The maximum number of retries the operation is allowed to do after a failure.\n\nA value of `0` (zero) means no retries are made. Defaults to: `0`.\n";
          type = (types.nullOr types.int);
        };
        "minorVersionUpgrade" = mkOption {
          description = "Configuration of minor version upgrade\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsSpecMinorVersionUpgrade"));
        };
        "op" = mkOption {
          description = "The kind of operation that will be performed on the SGCluster. Available operations are:\n\n* `benchmark`: run a benchmark on the specified SGCluster and report the results in the status.\n* `vacuum`: perform a [vacuum](https://www.postgresql.org/docs/current/sql-vacuum.html) operation on the specified SGCluster.\n* `repack`: run [`pg_repack`](https://github.com/reorg/pg_repack) command on the specified SGCluster.\n* `majorVersionUpgrade`: perform a major version upgrade of PostgreSQL using [`pg_upgrade`](https://www.postgresql.org/docs/current/pgupgrade.html) command.\n* `restart`: perform a restart of the cluster.\n* `minorVersionUpgrade`: perform a minor version upgrade of PostgreSQL.\n* `securityUpgrade`: perform a security upgrade of the cluster.\n";
          type = types.str;
        };
        "repack" = mkOption {
          description = "Configuration of [`pg_repack`](https://github.com/reorg/pg_repack) command\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsSpecRepack"));
        };
        "restart" = mkOption {
          description = "Configuration of restart\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsSpecRestart"));
        };
        "runAt" = mkOption {
          description = "An ISO 8601 date, that holds UTC scheduled date of the operation execution.\n\nIf not specified or if the date it's in the past, it will be interpreted ASAP.\n";
          type = (types.nullOr types.str);
        };
        "scheduling" = mkOption {
          description = "Pod custom node scheduling and affinity configuration";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsSpecScheduling"));
        };
        "securityUpgrade" = mkOption {
          description = "Configuration of security upgrade\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsSpecSecurityUpgrade"));
        };
        "sgCluster" = mkOption {
          description = "The name of SGCluster on which the operation will be performed.\n";
          type = types.str;
        };
        "timeout" = mkOption {
          description = "An ISO 8601 duration in the format `PnDTnHnMn.nS`, that specifies a timeout after which the operation execution will be canceled.\n\nIf the operation can not be performed due to timeout expiration, the condition `Failed` will have a status of `True` and the reason will be `OperationTimedOut`.\n\nIf not specified the operation will never fail for timeout expiration.\n";
          type = (types.nullOr types.str);
        };
        "vacuum" = mkOption {
          description = "Configuration of [vacuum](https://www.postgresql.org/docs/current/sql-vacuum.html) operation\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsSpecVacuum"));
        };
      };

      config = {
        "benchmark" = mkOverride 1002 null;
        "majorVersionUpgrade" = mkOverride 1002 null;
        "maxRetries" = mkOverride 1002 null;
        "minorVersionUpgrade" = mkOverride 1002 null;
        "repack" = mkOverride 1002 null;
        "restart" = mkOverride 1002 null;
        "runAt" = mkOverride 1002 null;
        "scheduling" = mkOverride 1002 null;
        "securityUpgrade" = mkOverride 1002 null;
        "timeout" = mkOverride 1002 null;
        "vacuum" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecBenchmark" = {

      options = {
        "connectionType" = mkOption {
          description = "Specify the service where the benchmark will connect to:\n\n* `primary-service`: Connect to the primary service\n* `replicas-service`: Connect to the replicas service\n";
          type = (types.nullOr types.str);
        };
        "credentials" = mkOption {
          description = "The credentials of the user that will be used by the benchmark";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsSpecBenchmarkCredentials"));
        };
        "database" = mkOption {
          description = "When specified will indicate the database where the benchmark will run upon.\n\nIf not specified a target database with a random name will be created and removed after the benchmark completes.\n";
          type = (types.nullOr types.str);
        };
        "pgbench" = mkOption {
          description = "Configuration of [pgbench](https://www.postgresql.org/docs/current/pgbench.html) benchmark\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsSpecBenchmarkPgbench"));
        };
        "sampling" = mkOption {
          description = "Configuration of sampling benchmark.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsSpecBenchmarkSampling"));
        };
        "type" = mkOption {
          description = "The type of benchmark that will be performed on the SGCluster. Available benchmarks are:\n\n* `pgbench`: run [pgbench](https://www.postgresql.org/docs/current/pgbench.html) on the specified SGCluster and report the results in the status.\n* `sampling`: samples real queries and store them in the SGDbOps status in order to be used by a `pgbench` benchmark using `replay` mode.\n";
          type = types.str;
        };
      };

      config = {
        "connectionType" = mkOverride 1002 null;
        "credentials" = mkOverride 1002 null;
        "database" = mkOverride 1002 null;
        "pgbench" = mkOverride 1002 null;
        "sampling" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecBenchmarkCredentials" = {

      options = {
        "password" = mkOption {
          description = "The password that will be used by the benchmark\n\nIf not specified the default superuser password will be used.\n";
          type = (submoduleOf "stackgres.io.v1.SGDbOpsSpecBenchmarkCredentialsPassword");
        };
        "username" = mkOption {
          description = "The username that will be used by the benchmark.\n\nIf not specified the default superuser username (by default postgres) will be used.\n";
          type = (submoduleOf "stackgres.io.v1.SGDbOpsSpecBenchmarkCredentialsUsername");
        };
      };

      config = { };

    };
    "stackgres.io.v1.SGDbOpsSpecBenchmarkCredentialsPassword" = {

      options = {
        "key" = mkOption {
          description = "The Secret key where the password is stored.\n";
          type = types.str;
        };
        "name" = mkOption {
          description = "The Secret name where the password is stored.\n";
          type = types.str;
        };
      };

      config = { };

    };
    "stackgres.io.v1.SGDbOpsSpecBenchmarkCredentialsUsername" = {

      options = {
        "key" = mkOption {
          description = "The Secret key where the username is stored.\n";
          type = types.str;
        };
        "name" = mkOption {
          description = "The Secret name where the username is stored.\n";
          type = types.str;
        };
      };

      config = { };

    };
    "stackgres.io.v1.SGDbOpsSpecBenchmarkPgbench" = {

      options = {
        "concurrentClients" = mkOption {
          description = "Number of clients simulated, that is, number of concurrent database sessions. Defaults to: `1`.\n";
          type = (types.nullOr types.int);
        };
        "custom" = mkOption {
          description = "This section allow to configure custom SQL for initialization and scripts used by pgbench.";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsSpecBenchmarkPgbenchCustom"));
        };
        "databaseSize" = mkOption {
          description = "Size of the database to generate. This size is specified either in Mebibytes, Gibibytes or Tebibytes (multiples of 2^20, 2^30 or 2^40, respectively).\n";
          type = types.str;
        };
        "duration" = mkOption {
          description = "An ISO 8601 duration in the format `PnDTnHnMn.nS`, that specifies how long the benchmark will run.\n";
          type = types.str;
        };
        "fillfactor" = mkOption {
          description = "Create the pgbench_accounts, pgbench_tellers and pgbench_branches tables with the given fillfactor. Default is 100.\n";
          type = (types.nullOr types.int);
        };
        "foreignKeys" = mkOption {
          description = "Create foreign key constraints between the standard tables. (This option only take effect if `custom.initiailization` is not specified).\n";
          type = (types.nullOr types.bool);
        };
        "initSteps" = mkOption {
          description = "Perform just a selected set of the normal initialization steps. init_steps specifies the initialization steps to be performed, using one character per step. Each step is invoked in the specified order. The default is dtgvp. The available steps are:\n\n* `d` (Drop): Drop any existing pgbench tables.\n* `t` (create Tables): Create the tables used by the standard pgbench scenario, namely pgbench_accounts, pgbench_branches, pgbench_history, and pgbench_tellers.\n* `g` or `G` (Generate data, client-side or server-side): Generate data and load it into the standard tables, replacing any data already present.\n  With `g` (client-side data generation), data is generated in pgbench client and then sent to the server. This uses the client/server bandwidth extensively through a COPY. pgbench uses the FREEZE option with version 14 or later of PostgreSQL to speed up subsequent VACUUM, unless partitions are enabled. Using g causes logging to print one message every 100,000 rows while generating data for the pgbench_accounts table.\n  With `G` (server-side data generation), only small queries are sent from the pgbench client and then data is actually generated in the server. No significant bandwidth is required for this variant, but the server will do more work. Using G causes logging not to print any progress message while generating data.\n  The default initialization behavior uses client-side data generation (equivalent to g).\n* `v` (Vacuum): Invoke VACUUM on the standard tables.\n* `p` (create Primary keys): Create primary key indexes on the standard tables.\n* `f` (create Foreign keys): Create foreign key constraints between the standard tables. (Note that this step is not performed by default.)\n";
          type = (types.nullOr types.str);
        };
        "mode" = mkOption {
          description = "The pgbench benchmark type:\n\n* `tpcb-like`: The benchmark is inspired by the [TPC-B benchmark](https://www.tpc.org/TPC_Documents_Latest_Versions/TPC-B_v2.0.0.pdf). It is the default mode when `connectionType` is set to `primary-service`.\n* `select-only`: The `tpcb-like` but only using SELECTs commands. It is the default mode when `connectionType` is set to `replicas-service`.\n* `custom`: will use the scripts in the `custom` section to initialize and and run commands for the benchmark.\n* `replay`: will replay the sampled queries of a sampling benchmark SGDbOps. If the `custom` section is specified it will be used instead. Queries can be referenced setting `custom.scripts.replay` to the index of the query in the sampling benchmark SGDbOps's status (index start from 0).\n\nSee also https://www.postgresql.org/docs/current/pgbench.html#TRANSACTIONS-AND-SCRIPTS\n";
          type = (types.nullOr types.str);
        };
        "noVacuum" = mkOption {
          description = "Perform no vacuuming during initialization. (This option suppresses the `v` initialization step, even if it was specified in `initSteps`.)\n";
          type = (types.nullOr types.bool);
        };
        "partitionMethod" = mkOption {
          description = "Create a partitioned pgbench_accounts table with the specified method. Expected values are `range` or `hash`. This option requires that partitions is set to non-zero. If unspecified, default is `range`. (This option only take effect if `custom.initiailization` is not specified).\n";
          type = (types.nullOr types.str);
        };
        "partitions" = mkOption {
          description = "Create a partitioned pgbench_accounts table with the specified number of partitions of nearly equal size for the scaled number of accounts. Default is 0, meaning no partitioning. (This option only take effect if `custom.initiailization` is not specified).\n";
          type = (types.nullOr types.int);
        };
        "queryMode" = mkOption {
          description = "Protocol to use for submitting queries to the server:\n\n* `simple`: use simple query protocol.\n* `extended`: use extended query protocol.\n* `prepared`: use extended query protocol with prepared statements.\n\nIn the prepared mode, pgbench reuses the parse analysis result starting from the second query iteration, so pgbench runs faster than in other modes.\n\nThe default is `simple` query protocol. See also https://www.postgresql.org/docs/current/protocol.html\n";
          type = (types.nullOr types.str);
        };
        "samplingRate" = mkOption {
          description = "Sampling rate, used when collecting data, to reduce the amount of collected data. If this option is given, only the specified fraction of transactions are collected. 1.0 means all transactions will be logged, 0.05 means only 5% of the transactions will be logged.\n";
          type = (types.nullOr types.int);
        };
        "samplingSGDbOps" = mkOption {
          description = "benchmark SGDbOps of type sampling that will be used to replay sampled queries.";
          type = (types.nullOr types.str);
        };
        "threads" = mkOption {
          description = "Number of worker threads within pgbench. Using more than one thread can be helpful on multi-CPU machines. Clients are distributed as evenly as possible among available threads. Default is `1`.\n";
          type = (types.nullOr types.int);
        };
        "unloggedTables" = mkOption {
          description = "Create all tables as unlogged tables, rather than permanent tables. (This option only take effect if `custom.initiailization` is not specified).\n";
          type = (types.nullOr types.bool);
        };
        "usePreparedStatements" = mkOption {
          description = "**Deprecated** this field is ignored, use `queryMode` instead.\n\nUse extended query protocol with prepared statements. Defaults to: `false`.\n";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "concurrentClients" = mkOverride 1002 null;
        "custom" = mkOverride 1002 null;
        "fillfactor" = mkOverride 1002 null;
        "foreignKeys" = mkOverride 1002 null;
        "initSteps" = mkOverride 1002 null;
        "mode" = mkOverride 1002 null;
        "noVacuum" = mkOverride 1002 null;
        "partitionMethod" = mkOverride 1002 null;
        "partitions" = mkOverride 1002 null;
        "queryMode" = mkOverride 1002 null;
        "samplingRate" = mkOverride 1002 null;
        "samplingSGDbOps" = mkOverride 1002 null;
        "threads" = mkOverride 1002 null;
        "unloggedTables" = mkOverride 1002 null;
        "usePreparedStatements" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecBenchmarkPgbenchCustom" = {

      options = {
        "initialization" = mkOption {
          description = "The custom SQL for initialization that will be executed in place of pgbench default initialization.\n\nIf not specified the default pgbench initialization will be performed instead.\n";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsSpecBenchmarkPgbenchCustomInitialization")
          );
        };
        "scripts" = mkOption {
          description = "The custom SQL scripts that will be executed by pgbench during the benchmark instead of default pgbench scripts";
          type = (
            types.nullOr (types.listOf (submoduleOf "stackgres.io.v1.SGDbOpsSpecBenchmarkPgbenchCustomScripts"))
          );
        };
      };

      config = {
        "initialization" = mkOverride 1002 null;
        "scripts" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecBenchmarkPgbenchCustomInitialization" = {

      options = {
        "script" = mkOption {
          description = "Raw SQL script to execute. This field is mutually exclusive with `scriptFrom` field.\n";
          type = (types.nullOr types.str);
        };
        "scriptFrom" = mkOption {
          description = "Reference to either a Kubernetes [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) or a [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) that contains the SQL script to execute. This field is mutually exclusive with `script` field.\n\nFields `secretKeyRef` and `configMapKeyRef` are mutually exclusive, and one of them is required.\n";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGDbOpsSpecBenchmarkPgbenchCustomInitializationScriptFrom"
            )
          );
        };
      };

      config = {
        "script" = mkOverride 1002 null;
        "scriptFrom" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecBenchmarkPgbenchCustomInitializationScriptFrom" = {

      options = {
        "configMapKeyRef" = mkOption {
          description = "A [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) reference that contains the SQL script to execute. This field is mutually exclusive with `secretKeyRef` field.\n";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGDbOpsSpecBenchmarkPgbenchCustomInitializationScriptFromConfigMapKeyRef"
            )
          );
        };
        "secretKeyRef" = mkOption {
          description = "A Kubernetes [SecretKeySelector](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#secretkeyselector-v1-core) that contains the SQL script to execute. This field is mutually exclusive with `configMapKeyRef` field.\n";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGDbOpsSpecBenchmarkPgbenchCustomInitializationScriptFromSecretKeyRef"
            )
          );
        };
      };

      config = {
        "configMapKeyRef" = mkOverride 1002 null;
        "secretKeyRef" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecBenchmarkPgbenchCustomInitializationScriptFromConfigMapKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key name within the ConfigMap that contains the SQL script to execute.\n";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the ConfigMap that contains the SQL script to execute.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecBenchmarkPgbenchCustomInitializationScriptFromSecretKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from. Must be a valid secret key.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecBenchmarkPgbenchCustomScripts" = {

      options = {
        "builtin" = mkOption {
          description = "The name of the builtin script to use. See https://www.postgresql.org/docs/current/pgbench.html#PGBENCH-OPTION-BUILTIN\n\nWhen specified fields `replay`, `script` and `scriptFrom` must not be set.\n";
          type = (types.nullOr types.str);
        };
        "replay" = mkOption {
          description = "The index of the query in the sampling benchmark SGDbOps's status (index start from 0).\n\nWhen specified fields `builtin`, `script` and `scriptFrom` must not be set.\n";
          type = (types.nullOr types.int);
        };
        "script" = mkOption {
          description = "Raw SQL script to execute. This field is mutually exclusive with `scriptFrom` field.\n";
          type = (types.nullOr types.str);
        };
        "scriptFrom" = mkOption {
          description = "Reference to either a Kubernetes [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) or a [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) that contains the SQL script to execute. This field is mutually exclusive with `script` field.\n\nFields `secretKeyRef` and `configMapKeyRef` are mutually exclusive, and one of them is required.\n";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsSpecBenchmarkPgbenchCustomScriptsScriptFrom")
          );
        };
        "weight" = mkOption {
          description = "The weight of this custom SQL script.";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "builtin" = mkOverride 1002 null;
        "replay" = mkOverride 1002 null;
        "script" = mkOverride 1002 null;
        "scriptFrom" = mkOverride 1002 null;
        "weight" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecBenchmarkPgbenchCustomScriptsScriptFrom" = {

      options = {
        "configMapKeyRef" = mkOption {
          description = "A [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) reference that contains the SQL script to execute. This field is mutually exclusive with `secretKeyRef` field.\n";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGDbOpsSpecBenchmarkPgbenchCustomInitializationScriptFromConfigMapKeyRef"
            )
          );
        };
        "secretKeyRef" = mkOption {
          description = "A Kubernetes [SecretKeySelector](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#secretkeyselector-v1-core) that contains the SQL script to execute. This field is mutually exclusive with `configMapKeyRef` field.\n";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGDbOpsSpecBenchmarkPgbenchCustomInitializationScriptFromSecretKeyRef"
            )
          );
        };
      };

      config = {
        "configMapKeyRef" = mkOverride 1002 null;
        "secretKeyRef" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecBenchmarkSampling" = {

      options = {
        "customTopQueriesQuery" = mkOption {
          description = "The query used to select top queries. Will be ignored if `mode` is not set to `custom`.\n\nThe query must return at most 2 columns:\n\n* First column returned by the query must be a column holding the query identifier, also available in pg_stat_activity (column `query_id`) and pg_stat_statements (column `queryid`).\n* Second column is optional and, if returned, must hold a json object containing only text keys and values stat will be used to generate the stats.\n\nSee also:\n\n* https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW\n* https://www.postgresql.org/docs/current/pgstatstatements.html#PGSTATSTATEMENTS-PG-STAT-STATEMENTS\n";
          type = (types.nullOr types.str);
        };
        "mode" = mkOption {
          description = "The mode used to select the top queries used for sampling:\n\n* `time`: The top queries will be selected among the most slow queries.\n* `calls`: The top queries will be selected among the most called queries.\n* `custom`: The `customTopQueriesQuery` will be used to select top queries.\n";
          type = (types.nullOr types.str);
        };
        "omitTopQueriesInStatus" = mkOption {
          description = "When `true` omit to include the top queries stats in the SGDbOps status. By default `false`.";
          type = (types.nullOr types.bool);
        };
        "queries" = mkOption {
          description = "Number of sampled queries to include in the result. By default `10`.";
          type = (types.nullOr types.int);
        };
        "samplingDuration" = mkOption {
          description = "An ISO 8601 duration in the format `PnDTnHnMn.nS`, that specifies how long will last the sampling of real queries that will be replayed later.";
          type = types.str;
        };
        "samplingMinInterval" = mkOption {
          description = "Minimum number of microseconds the sampler will wait between each sample is taken. By default `10000` (10 milliseconds).";
          type = (types.nullOr types.int);
        };
        "targetDatabase" = mkOption {
          description = "The target database to be sampled. By default `postgres`.\n\nThe benchmark database will be used to store the sampled queries but user must specify a target database to be sampled in the `sampling` section.\n";
          type = types.str;
        };
        "topQueriesCollectDuration" = mkOption {
          description = "An ISO 8601 duration in the format `PnDTnHnMn.nS`, that specifies how long the to wait before selecting top queries in order to collect enough stats.";
          type = types.str;
        };
        "topQueriesFilter" = mkOption {
          description = "Regular expression for filtering representative statements when selecting top queries. Will be ignored if `mode` is set to `custom`. By default is `^ *(with|select) `. See https://www.postgresql.org/docs/current/functions-matching.html#FUNCTIONS-POSIX-REGEXP";
          type = (types.nullOr types.str);
        };
        "topQueriesMin" = mkOption {
          description = "Minimum number of queries to consider as part of the top queries. By default `5`.";
          type = (types.nullOr types.int);
        };
        "topQueriesPercentile" = mkOption {
          description = "Percentile of queries to consider as part of the top queries. Will be ignored if `mode` is set to `custom`. By default `95`.";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "customTopQueriesQuery" = mkOverride 1002 null;
        "mode" = mkOverride 1002 null;
        "omitTopQueriesInStatus" = mkOverride 1002 null;
        "queries" = mkOverride 1002 null;
        "samplingMinInterval" = mkOverride 1002 null;
        "topQueriesFilter" = mkOverride 1002 null;
        "topQueriesMin" = mkOverride 1002 null;
        "topQueriesPercentile" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecMajorVersionUpgrade" = {

      options = {
        "backupPath" = mkOption {
          description = "The path were the backup is stored. If not set this field is filled up by the operator.\n\nWhen provided will indicate were the backups and WAL files will be stored.\n\nThe path should be different from the current `.spec.configurations.backups[].path` value for the target `SGCluster`\n  in order to avoid mixing WAL files of two distinct major versions of postgres.\n";
          type = (types.nullOr types.str);
        };
        "check" = mkOption {
          description = "If true does some checks to see if the cluster can perform a major version upgrade without changing any data. Defaults to: `false`.\n";
          type = (types.nullOr types.bool);
        };
        "clone" = mkOption {
          description = "If true use efficient file cloning (also known as \"reflinks\" on some systems) instead of copying files to the new cluster.\nThis can result in near-instantaneous copying of the data files, giving the speed advantages of `link` while leaving the old\n  cluster untouched. This option is mutually exclusive with `link`. Defaults to: `false`.\n\nFile cloning is only supported on some operating systems and file systems. If it is selected but not supported, the pg_upgrade\n  run will error. At present, it is supported on Linux (kernel 4.5 or later) with Btrfs and XFS (on file systems created with\n  reflink support), and on macOS with APFS.\n";
          type = (types.nullOr types.bool);
        };
        "link" = mkOption {
          description = "If true use hard links instead of copying files to the new cluster. This option is mutually exclusive with `clone`. Defaults to: `false`.\n";
          type = (types.nullOr types.bool);
        };
        "maxErrorsAfterUpgrade" = mkOption {
          description = "Indicates the number of errors that the operation can tolerate after the upgrade\n is performed in order to wait for the Pod to become ready and set the operation\n as completed.\n";
          type = (types.nullOr types.int);
        };
        "postgresExtensions" = mkOption {
          description = "A major version upgrade can not be performed if a required extension is not present for the target major version of the upgrade.\nIn those cases you will have to provide the target extension version of the extension for the target major version of postgres.\nBeware that in some cases it is not possible to upgrade an extension alongside postgres. This is the case for PostGIS or timescaledb.\n In such cases you will have to upgrade the extension before or after the major version upgrade. Please make sure you read the\n documentation of each extension in order to understand if it is possible to upgrade it during a major version upgrade of postgres.\n";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "stackgres.io.v1.SGDbOpsSpecMajorVersionUpgradePostgresExtensions"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "postgresVersion" = mkOption {
          description = "The target postgres version that must have the same major version of the target SGCluster.\n";
          type = (types.nullOr types.str);
        };
        "sgPostgresConfig" = mkOption {
          description = "The postgres config that must have the same major version of the target postgres version.\n";
          type = (types.nullOr types.str);
        };
        "toInstallPostgresExtensions" = mkOption {
          description = "The list of Postgres extensions to install.\n\n**This section is filled by the operator.**\n";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "stackgres.io.v1.SGDbOpsSpecMajorVersionUpgradeToInstallPostgresExtensions"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
      };

      config = {
        "backupPath" = mkOverride 1002 null;
        "check" = mkOverride 1002 null;
        "clone" = mkOverride 1002 null;
        "link" = mkOverride 1002 null;
        "maxErrorsAfterUpgrade" = mkOverride 1002 null;
        "postgresExtensions" = mkOverride 1002 null;
        "postgresVersion" = mkOverride 1002 null;
        "sgPostgresConfig" = mkOverride 1002 null;
        "toInstallPostgresExtensions" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecMajorVersionUpgradePostgresExtensions" = {

      options = {
        "name" = mkOption {
          description = "The name of the extension to deploy.";
          type = types.str;
        };
        "publisher" = mkOption {
          description = "The id of the publisher of the extension to deploy. If not specified `com.ongres` will be used by default.";
          type = (types.nullOr types.str);
        };
        "repository" = mkOption {
          description = "The repository base URL from where to obtain the extension to deploy.\n\n**This section is filled by the operator.**\n";
          type = (types.nullOr types.str);
        };
        "version" = mkOption {
          description = "The version of the extension to deploy. If not specified version of `stable` channel will be used by default and if only a version is available that one will be used.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "publisher" = mkOverride 1002 null;
        "repository" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecMajorVersionUpgradeToInstallPostgresExtensions" = {

      options = {
        "build" = mkOption {
          description = "The build version of the extension to install.";
          type = (types.nullOr types.str);
        };
        "extraMounts" = mkOption {
          description = "The extra mounts of the extension to install.";
          type = (types.nullOr (types.listOf types.str));
        };
        "name" = mkOption {
          description = "The name of the extension to install.";
          type = types.str;
        };
        "postgresVersion" = mkOption {
          description = "The postgres major version of the extension to install.";
          type = types.str;
        };
        "publisher" = mkOption {
          description = "The id of the publisher of the extension to install.";
          type = types.str;
        };
        "repository" = mkOption {
          description = "The repository base URL from where the extension will be installed from.";
          type = types.str;
        };
        "version" = mkOption {
          description = "The version of the extension to install.";
          type = types.str;
        };
      };

      config = {
        "build" = mkOverride 1002 null;
        "extraMounts" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecMinorVersionUpgrade" = {

      options = {
        "method" = mkOption {
          description = "The method used to perform the minor version upgrade operation. Available methods are:\n\n* `InPlace`: the in-place method does not require more resources than those that are available.\n  In case only an instance of the StackGres cluster is present this mean the service disruption will\n  last longer so we encourage use the reduced impact restart and especially for a production environment.\n* `ReducedImpact`: this procedure is the same as the in-place method but require additional\n  resources in order to spawn a new updated replica that will be removed when the procedure completes.\n";
          type = (types.nullOr types.str);
        };
        "postgresVersion" = mkOption {
          description = "The target postgres version that must have the same major version of the target SGCluster.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "method" = mkOverride 1002 null;
        "postgresVersion" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecRepack" = {

      options = {
        "databases" = mkOption {
          description = "List of database to vacuum or repack, don't specify to select all databases\n";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "stackgres.io.v1.SGDbOpsSpecRepackDatabases" "name" [ ]
            )
          );
          apply = attrsToList;
        };
        "excludeExtension" = mkOption {
          description = "If true don't repack tables which belong to specific extension. Defaults to: `false`.\n";
          type = (types.nullOr types.bool);
        };
        "noAnalyze" = mkOption {
          description = "If true don't analyze at end. Defaults to: `false`.\n";
          type = (types.nullOr types.bool);
        };
        "noKillBackend" = mkOption {
          description = "If true don't kill other backends when timed out. Defaults to: `false`.\n";
          type = (types.nullOr types.bool);
        };
        "noOrder" = mkOption {
          description = "If true do vacuum full instead of cluster. Defaults to: `false`.\n";
          type = (types.nullOr types.bool);
        };
        "waitTimeout" = mkOption {
          description = "If specified, an ISO 8601 duration format `PnDTnHnMn.nS` to set a timeout to cancel other backends on conflict.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "databases" = mkOverride 1002 null;
        "excludeExtension" = mkOverride 1002 null;
        "noAnalyze" = mkOverride 1002 null;
        "noKillBackend" = mkOverride 1002 null;
        "noOrder" = mkOverride 1002 null;
        "waitTimeout" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecRepackDatabases" = {

      options = {
        "excludeExtension" = mkOption {
          description = "If true don't repack tables which belong to specific extension. Defaults to: `false`.\n";
          type = (types.nullOr types.bool);
        };
        "name" = mkOption {
          description = "the name of the database";
          type = types.str;
        };
        "noAnalyze" = mkOption {
          description = "If true don't analyze at end. Defaults to: `false`.\n";
          type = (types.nullOr types.bool);
        };
        "noKillBackend" = mkOption {
          description = "If true don't kill other backends when timed out. Defaults to: `false`.\n";
          type = (types.nullOr types.bool);
        };
        "noOrder" = mkOption {
          description = "If true do vacuum full instead of cluster. Defaults to: `false`.\n";
          type = (types.nullOr types.bool);
        };
        "waitTimeout" = mkOption {
          description = "If specified, an ISO 8601 duration format `PnDTnHnMn.nS` to set a timeout to cancel other backends on conflict.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "excludeExtension" = mkOverride 1002 null;
        "noAnalyze" = mkOverride 1002 null;
        "noKillBackend" = mkOverride 1002 null;
        "noOrder" = mkOverride 1002 null;
        "waitTimeout" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecRestart" = {

      options = {
        "method" = mkOption {
          description = "The method used to perform the restart operation. Available methods are:\n\n* `InPlace`: the in-place method does not require more resources than those that are available.\n  In case only an instance of the StackGres cluster is present this mean the service disruption will\n  last longer so we encourage use the reduced impact restart and especially for a production environment.\n* `ReducedImpact`: this procedure is the same as the in-place method but require additional\n  resources in order to spawn a new updated replica that will be removed when the procedure completes.\n";
          type = (types.nullOr types.str);
        };
        "onlyPendingRestart" = mkOption {
          description = "By default all Pods are restarted. Setting this option to `true` allow to restart only those Pods which\n  are in pending restart state as detected by the operation. Defaults to: `false`.\n";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "method" = mkOverride 1002 null;
        "onlyPendingRestart" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecScheduling" = {

      options = {
        "nodeAffinity" = mkOption {
          description = "Node affinity is a group of node affinity scheduling rules.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#nodeaffinity-v1-core";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingNodeAffinity"));
        };
        "nodeSelector" = mkOption {
          description = "NodeSelector is a selector which must be true for the pod to fit on a node. Selector which must match a node's labels for the pod to be scheduled on that node. More info: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/\n";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "podAffinity" = mkOption {
          description = "Pod affinity is a group of inter pod affinity scheduling rules.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#podaffinity-v1-core";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinity"));
        };
        "podAntiAffinity" = mkOption {
          description = "Pod anti affinity is a group of inter pod anti affinity scheduling rules.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#podantiaffinity-v1-core";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinity"));
        };
        "priorityClassName" = mkOption {
          description = "If specified, indicates the pod's priority. \"system-node-critical\" and \"system-cluster-critical\" are two special keywords which indicate the highest priorities with the former being the highest priority. Any other name must be defined by creating a PriorityClass object with that name. If not specified, the pod priority will be default or zero if there is no default.";
          type = (types.nullOr types.str);
        };
        "tolerations" = mkOption {
          description = "If specified, the pod's tolerations.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#toleration-v1-core";
          type = (
            types.nullOr (types.listOf (submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingTolerations"))
          );
        };
      };

      config = {
        "nodeAffinity" = mkOverride 1002 null;
        "nodeSelector" = mkOverride 1002 null;
        "podAffinity" = mkOverride 1002 null;
        "podAntiAffinity" = mkOverride 1002 null;
        "priorityClassName" = mkOverride 1002 null;
        "tolerations" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecSchedulingNodeAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy the affinity expressions specified by this field, but it may choose a node that violates one or more of the expressions. The node that is most preferred is the one with the greatest sum of weights, i.e. for each node that meets all of the scheduling requirements (resource request, requiredDuringScheduling affinity expressions, etc.), compute a sum by iterating through the elements of this field and adding \"weight\" to the sum if the node matches the corresponding matchExpressions; the node(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "A node selector represents the union of the results of one or more label queries over a set of nodes; that is, it represents the OR of the selectors represented by the node selector terms.";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution"
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "preference" = mkOption {
            description = "A null or empty node selector term matches no objects. The requirements of them are ANDed. The TopologySelectorTerm type implements a subset of the NodeSelectorTerm.";
            type = (
              submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference"
            );
          };
          "weight" = mkOption {
            description = "Weight associated with matching the corresponding nodeSelectorTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields"
                )
              )
            );
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchFields" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "nodeSelectorTerms" = mkOption {
            description = "Required. A list of node selector terms. The terms are ORed.";
            type = (
              types.listOf (
                submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms"
              )
            );
          };
        };

        config = { };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields"
                )
              )
            );
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchFields" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy the affinity expressions specified by this field, but it may choose a node that violates one or more of the expressions. The node that is most preferred is the one with the greatest sum of weights, i.e. for each node that meets all of the scheduling requirements (resource request, requiredDuringScheduling affinity expressions, etc.), compute a sum by iterating through the elements of this field and adding \"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the node(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at scheduling time, the pod will not be scheduled onto the node. If the affinity requirements specified by this field cease to be met at some point during pod execution (e.g. due to a pod label update), the system may or may not try to eventually evict the pod from its node. When there are multiple elements, the lists of nodes corresponding to each podAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Defines a set of pods (namely those matching the labelSelector relative to the given namespace(s)) that this pod should be co-located (affinity) or not co-located (anti-affinity) with, where co-located is defined as running on a node whose value of the label with key <topologyKey> matches that of any node on which a pod of the set of pods is running";
            type = (
              submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both matchLabelKeys and labelSelector. Also, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both mismatchLabelKeys and labelSelector. Also, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecution" = {

      options = {
        "labelSelector" = mkOption {
          description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
            )
          );
        };
        "matchLabelKeys" = mkOption {
          description = "MatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both matchLabelKeys and labelSelector. Also, matchLabelKeys cannot be set when labelSelector isn't set.";
          type = (types.nullOr (types.listOf types.str));
        };
        "mismatchLabelKeys" = mkOption {
          description = "MismatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both mismatchLabelKeys and labelSelector. Also, mismatchLabelKeys cannot be set when labelSelector isn't set.";
          type = (types.nullOr (types.listOf types.str));
        };
        "namespaceSelector" = mkOption {
          description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
            )
          );
        };
        "namespaces" = mkOption {
          description = "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
          type = (types.nullOr (types.listOf types.str));
        };
        "topologyKey" = mkOption {
          description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed.";
          type = types.str;
        };
      };

      config = {
        "labelSelector" = mkOverride 1002 null;
        "matchLabelKeys" = mkOverride 1002 null;
        "mismatchLabelKeys" = mkOverride 1002 null;
        "namespaceSelector" = mkOverride 1002 null;
        "namespaces" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy the anti-affinity expressions specified by this field, but it may choose a node that violates one or more of the expressions. The node that is most preferred is the one with the greatest sum of weights, i.e. for each node that meets all of the scheduling requirements (resource request, requiredDuringScheduling anti-affinity expressions, etc.), compute a sum by iterating through the elements of this field and adding \"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the node(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the anti-affinity requirements specified by this field are not met at scheduling time, the pod will not be scheduled onto the node. If the anti-affinity requirements specified by this field cease to be met at some point during pod execution (e.g. due to a pod label update), the system may or may not try to eventually evict the pod from its node. When there are multiple elements, the lists of nodes corresponding to each podAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Defines a set of pods (namely those matching the labelSelector relative to the given namespace(s)) that this pod should be co-located (affinity) or not co-located (anti-affinity) with, where co-located is defined as running on a node whose value of the label with key <topologyKey> matches that of any node on which a pod of the set of pods is running";
            type = (
              submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both matchLabelKeys and labelSelector. Also, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both mismatchLabelKeys and labelSelector. Also, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both matchLabelKeys and labelSelector. Also, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both mismatchLabelKeys and labelSelector. Also, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsSpecSchedulingTolerations" = {

      options = {
        "effect" = mkOption {
          description = "Effect indicates the taint effect to match. Empty means match all taint effects. When specified, allowed values are NoSchedule, PreferNoSchedule and NoExecute.";
          type = (types.nullOr types.str);
        };
        "key" = mkOption {
          description = "Key is the taint key that the toleration applies to. Empty means match all taint keys. If the key is empty, operator must be Exists; this combination means to match all values and all keys.";
          type = (types.nullOr types.str);
        };
        "operator" = mkOption {
          description = "Operator represents a key's relationship to the value. Valid operators are Exists and Equal. Defaults to Equal. Exists is equivalent to wildcard for value, so that a pod can tolerate all taints of a particular category.";
          type = (types.nullOr types.str);
        };
        "tolerationSeconds" = mkOption {
          description = "TolerationSeconds represents the period of time the toleration (which must be of effect NoExecute, otherwise this field is ignored) tolerates the taint. By default, it is not set, which means tolerate the taint forever (do not evict). Zero and negative values will be treated as 0 (evict immediately) by the system.";
          type = (types.nullOr types.int);
        };
        "value" = mkOption {
          description = "Value is the taint value the toleration matches to. If the operator is Exists, the value should be empty, otherwise just a regular string.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "effect" = mkOverride 1002 null;
        "key" = mkOverride 1002 null;
        "operator" = mkOverride 1002 null;
        "tolerationSeconds" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecSecurityUpgrade" = {

      options = {
        "method" = mkOption {
          description = "The method used to perform the security upgrade operation. Available methods are:\n\n* `InPlace`: the in-place method does not require more resources than those that are available.\n  In case only an instance of the StackGres cluster is present this mean the service disruption will\n  last longer so we encourage use the reduced impact restart and especially for a production environment.\n* `ReducedImpact`: this procedure is the same as the in-place method but require additional\n  resources in order to spawn a new updated replica that will be removed when the procedure completes.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "method" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecVacuum" = {

      options = {
        "analyze" = mkOption {
          description = "If true, updates statistics used by the planner to determine the most efficient way to execute a query. Defaults to: `true`.\n";
          type = (types.nullOr types.bool);
        };
        "databases" = mkOption {
          description = "List of databases to vacuum or repack, don't specify to select all databases\n";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "stackgres.io.v1.SGDbOpsSpecVacuumDatabases" "name" [ ]
            )
          );
          apply = attrsToList;
        };
        "disablePageSkipping" = mkOption {
          description = "Normally, VACUUM will skip pages based on the visibility map. Pages where all tuples are known to be frozen can always be\n  skipped, and those where all tuples are known to be visible to all transactions may be skipped except when performing an\n  aggressive vacuum. Furthermore, except when performing an aggressive vacuum, some pages may be skipped in order to avoid\n  waiting for other sessions to finish using them. This option disables all page-skipping behavior, and is intended to be\n  used only when the contents of the visibility map are suspect, which should happen only if there is a hardware or\n  software issue causing database corruption. Defaults to: `false`.\n";
          type = (types.nullOr types.bool);
        };
        "freeze" = mkOption {
          description = "If true selects aggressive \"freezing\" of tuples. Specifying FREEZE is equivalent to performing VACUUM with the\n  vacuum_freeze_min_age and vacuum_freeze_table_age parameters set to zero. Aggressive freezing is always performed\n  when the table is rewritten, so this option is redundant when FULL is specified. Defaults to: `false`.\n";
          type = (types.nullOr types.bool);
        };
        "full" = mkOption {
          description = "If true selects \"full\" vacuum, which can reclaim more space, but takes much longer and exclusively locks the table.\nThis method also requires extra disk space, since it writes a new copy of the table and doesn't release the old copy\n  until the operation is complete. Usually this should only be used when a significant amount of space needs to be\n  reclaimed from within the table. Defaults to: `false`.\n";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "analyze" = mkOverride 1002 null;
        "databases" = mkOverride 1002 null;
        "disablePageSkipping" = mkOverride 1002 null;
        "freeze" = mkOverride 1002 null;
        "full" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsSpecVacuumDatabases" = {

      options = {
        "analyze" = mkOption {
          description = "If true, updates statistics used by the planner to determine the most efficient way to execute a query. Defaults to: `true`.\n";
          type = (types.nullOr types.bool);
        };
        "disablePageSkipping" = mkOption {
          description = "Normally, VACUUM will skip pages based on the visibility map. Pages where all tuples are known to be frozen can always be\n  skipped, and those where all tuples are known to be visible to all transactions may be skipped except when performing an\n  aggressive vacuum. Furthermore, except when performing an aggressive vacuum, some pages may be skipped in order to avoid\n  waiting for other sessions to finish using them. This option disables all page-skipping behavior, and is intended to be\n  used only when the contents of the visibility map are suspect, which should happen only if there is a hardware or\n  software issue causing database corruption. Defaults to: `false`.\n";
          type = (types.nullOr types.bool);
        };
        "freeze" = mkOption {
          description = "If true selects aggressive \"freezing\" of tuples. Specifying FREEZE is equivalent to performing VACUUM with the\n  vacuum_freeze_min_age and vacuum_freeze_table_age parameters set to zero. Aggressive freezing is always performed\n  when the table is rewritten, so this option is redundant when FULL is specified. Defaults to: `false`.\n";
          type = (types.nullOr types.bool);
        };
        "full" = mkOption {
          description = "If true selects \"full\" vacuum, which can reclaim more space, but takes much longer and exclusively locks the table.\nThis method also requires extra disk space, since it writes a new copy of the table and doesn't release the old copy\n  until the operation is complete. Usually this should only be used when a significant amount of space needs to be\n  reclaimed from within the table. Defaults to: `false`.\n";
          type = (types.nullOr types.bool);
        };
        "name" = mkOption {
          description = "the name of the database";
          type = types.str;
        };
      };

      config = {
        "analyze" = mkOverride 1002 null;
        "disablePageSkipping" = mkOverride 1002 null;
        "freeze" = mkOverride 1002 null;
        "full" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsStatus" = {

      options = {
        "benchmark" = mkOption {
          description = "The results of the benchmark\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsStatusBenchmark"));
        };
        "conditions" = mkOption {
          description = "Possible conditions are:\n\n* Running: to indicate when the operation is actually running\n* Completed: to indicate when the operation has completed successfully\n* Failed: to indicate when the operation has failed\n";
          type = (types.nullOr (types.listOf (submoduleOf "stackgres.io.v1.SGDbOpsStatusConditions")));
        };
        "majorVersionUpgrade" = mkOption {
          description = "The results of a major version upgrade\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsStatusMajorVersionUpgrade"));
        };
        "minorVersionUpgrade" = mkOption {
          description = "The results of a minor version upgrade\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsStatusMinorVersionUpgrade"));
        };
        "opRetries" = mkOption {
          description = "The number of retries performed by the operation\n";
          type = (types.nullOr types.int);
        };
        "opStarted" = mkOption {
          description = "The ISO 8601 timestamp of when the operation started running\n";
          type = (types.nullOr types.str);
        };
        "restart" = mkOption {
          description = "The results of a restart\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsStatusRestart"));
        };
        "securityUpgrade" = mkOption {
          description = "The results of a security upgrade\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsStatusSecurityUpgrade"));
        };
      };

      config = {
        "benchmark" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "majorVersionUpgrade" = mkOverride 1002 null;
        "minorVersionUpgrade" = mkOverride 1002 null;
        "opRetries" = mkOverride 1002 null;
        "opStarted" = mkOverride 1002 null;
        "restart" = mkOverride 1002 null;
        "securityUpgrade" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsStatusBenchmark" = {

      options = {
        "pgbench" = mkOption {
          description = "The results of the pgbench benchmark";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsStatusBenchmarkPgbench"));
        };
        "sampling" = mkOption {
          description = "The results of the sampling benchmark";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsStatusBenchmarkSampling"));
        };
      };

      config = {
        "pgbench" = mkOverride 1002 null;
        "sampling" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsStatusBenchmarkPgbench" = {

      options = {
        "hdrHistogram" = mkOption {
          description = "Compressed and base 64 encoded HdrHistogram";
          type = (types.nullOr types.str);
        };
        "latency" = mkOption {
          description = "The latency results of the pgbench benchmark\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsStatusBenchmarkPgbenchLatency"));
        };
        "scaleFactor" = mkOption {
          description = "The scale factor used to run pgbench (`--scale`).\n";
          type = (types.nullOr types.int);
        };
        "statements" = mkOption {
          description = "Average per-statement latency (execution time from the perspective of the client) of each command after the benchmark finishes";
          type = (
            types.nullOr (types.listOf (submoduleOf "stackgres.io.v1.SGDbOpsStatusBenchmarkPgbenchStatements"))
          );
        };
        "transactionsPerSecond" = mkOption {
          description = "All the transactions per second results of the pgbench benchmark\n";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsStatusBenchmarkPgbenchTransactionsPerSecond")
          );
        };
        "transactionsProcessed" = mkOption {
          description = "The number of transactions processed.\n";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "hdrHistogram" = mkOverride 1002 null;
        "latency" = mkOverride 1002 null;
        "scaleFactor" = mkOverride 1002 null;
        "statements" = mkOverride 1002 null;
        "transactionsPerSecond" = mkOverride 1002 null;
        "transactionsProcessed" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsStatusBenchmarkPgbenchLatency" = {

      options = {
        "average" = mkOption {
          description = "Average latency of transactions\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsStatusBenchmarkPgbenchLatencyAverage"));
        };
        "standardDeviation" = mkOption {
          description = "The latency standard deviation of transactions.\n";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1.SGDbOpsStatusBenchmarkPgbenchLatencyStandardDeviation")
          );
        };
      };

      config = {
        "average" = mkOverride 1002 null;
        "standardDeviation" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsStatusBenchmarkPgbenchLatencyAverage" = {

      options = {
        "unit" = mkOption {
          description = "The latency measure unit\n";
          type = (types.nullOr types.str);
        };
        "value" = mkOption {
          description = "The latency average value\n";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "unit" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsStatusBenchmarkPgbenchLatencyStandardDeviation" = {

      options = {
        "unit" = mkOption {
          description = "The latency measure unit\n";
          type = (types.nullOr types.str);
        };
        "value" = mkOption {
          description = "The latency standard deviation value\n";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "unit" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsStatusBenchmarkPgbenchStatements" = {

      options = {
        "command" = mkOption {
          description = "The command";
          type = (types.nullOr types.str);
        };
        "latency" = mkOption {
          description = "Average latency of the command";
          type = (types.nullOr types.int);
        };
        "script" = mkOption {
          description = "The script index (`0` if no custom scripts have been defined)";
          type = (types.nullOr types.int);
        };
        "unit" = mkOption {
          description = "The average latency measure unit";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "command" = mkOverride 1002 null;
        "latency" = mkOverride 1002 null;
        "script" = mkOverride 1002 null;
        "unit" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsStatusBenchmarkPgbenchTransactionsPerSecond" = {

      options = {
        "excludingConnectionsEstablishing" = mkOption {
          description = "Number of Transactions Per Second (tps) excluding connection establishing.\n";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGDbOpsStatusBenchmarkPgbenchTransactionsPerSecondExcludingConnectionsEstablishing"
            )
          );
        };
        "includingConnectionsEstablishing" = mkOption {
          description = "Number of Transactions Per Second (tps) including connection establishing.\n";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGDbOpsStatusBenchmarkPgbenchTransactionsPerSecondIncludingConnectionsEstablishing"
            )
          );
        };
        "overTime" = mkOption {
          description = "The Transactions Per Second (tps) values aggregated over unit of time";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGDbOpsStatusBenchmarkPgbenchTransactionsPerSecondOverTime"
            )
          );
        };
      };

      config = {
        "excludingConnectionsEstablishing" = mkOverride 1002 null;
        "includingConnectionsEstablishing" = mkOverride 1002 null;
        "overTime" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsStatusBenchmarkPgbenchTransactionsPerSecondExcludingConnectionsEstablishing" =
      {

        options = {
          "unit" = mkOption {
            description = "Transactions Per Second (tps) measure unit\n";
            type = (types.nullOr types.str);
          };
          "value" = mkOption {
            description = "The Transactions Per Second (tps) excluding connections establishing value\n";
            type = (types.nullOr types.int);
          };
        };

        config = {
          "unit" = mkOverride 1002 null;
          "value" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsStatusBenchmarkPgbenchTransactionsPerSecondIncludingConnectionsEstablishing" =
      {

        options = {
          "unit" = mkOption {
            description = "Transactions Per Second (tps) measure unit\n";
            type = (types.nullOr types.str);
          };
          "value" = mkOption {
            description = "The Transactions Per Second (tps) including connections establishing value\n";
            type = (types.nullOr types.int);
          };
        };

        config = {
          "unit" = mkOverride 1002 null;
          "value" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDbOpsStatusBenchmarkPgbenchTransactionsPerSecondOverTime" = {

      options = {
        "intervalDuration" = mkOption {
          description = "The interval duration used to aggregate the transactions per second.";
          type = (types.nullOr types.int);
        };
        "intervalDurationUnit" = mkOption {
          description = "The interval duration measure unit";
          type = (types.nullOr types.str);
        };
        "values" = mkOption {
          description = "The Transactions Per Second (tps) values aggregated over unit of time";
          type = (types.nullOr (types.listOf types.int));
        };
        "valuesUnit" = mkOption {
          description = "The Transactions Per Second (tps) measures unit";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "intervalDuration" = mkOverride 1002 null;
        "intervalDurationUnit" = mkOverride 1002 null;
        "values" = mkOverride 1002 null;
        "valuesUnit" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsStatusBenchmarkSampling" = {

      options = {
        "queries" = mkOption {
          description = "The queries sampled.";
          type = (
            types.nullOr (types.listOf (submoduleOf "stackgres.io.v1.SGDbOpsStatusBenchmarkSamplingQueries"))
          );
        };
        "topQueries" = mkOption {
          description = "The top queries sampled with the stats from pg_stat_statements. If is omitted if `omitTopQueriesInStatus` is set to `true`.";
          type = (
            types.nullOr (types.listOf (submoduleOf "stackgres.io.v1.SGDbOpsStatusBenchmarkSamplingTopQueries"))
          );
        };
      };

      config = {
        "queries" = mkOverride 1002 null;
        "topQueries" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsStatusBenchmarkSamplingQueries" = {

      options = {
        "id" = mkOption {
          description = "The query id of the representative statement calculated by Postgres";
          type = (types.nullOr types.str);
        };
        "query" = mkOption {
          description = "A sampled SQL query";
          type = (types.nullOr types.str);
        };
        "timestamp" = mkOption {
          description = "The sampled query timestamp";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "id" = mkOverride 1002 null;
        "query" = mkOverride 1002 null;
        "timestamp" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsStatusBenchmarkSamplingTopQueries" = {

      options = {
        "id" = mkOption {
          description = "The query id of the representative statement calculated by Postgres";
          type = (types.nullOr types.str);
        };
        "stats" = mkOption {
          description = "stats collected by the top queries query";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "id" = mkOverride 1002 null;
        "stats" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "Last time the condition transitioned from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "A human-readable message indicating details about the transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "The reason for the condition last transition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "Status of the condition, one of `True`, `False` or `Unknown`.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "Type of deployment condition.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsStatusMajorVersionUpgrade" = {

      options = {
        "failure" = mkOption {
          description = "A failure message (when available)\n";
          type = (types.nullOr types.str);
        };
        "initialInstances" = mkOption {
          description = "The instances present when the operation started\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "pendingToRestartInstances" = mkOption {
          description = "The instances that are pending to be restarted\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "phase" = mkOption {
          description = "The phase the operation is or was executing)\n";
          type = (types.nullOr types.str);
        };
        "primaryInstance" = mkOption {
          description = "The primary instance when the operation started\n";
          type = (types.nullOr types.str);
        };
        "restartedInstances" = mkOption {
          description = "The instances that have been restarted\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "sourcePostgresVersion" = mkOption {
          description = "The postgres version currently used by the primary instance\n";
          type = (types.nullOr types.str);
        };
        "targetPostgresVersion" = mkOption {
          description = "The postgres version that the cluster will be upgraded to\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "failure" = mkOverride 1002 null;
        "initialInstances" = mkOverride 1002 null;
        "pendingToRestartInstances" = mkOverride 1002 null;
        "phase" = mkOverride 1002 null;
        "primaryInstance" = mkOverride 1002 null;
        "restartedInstances" = mkOverride 1002 null;
        "sourcePostgresVersion" = mkOverride 1002 null;
        "targetPostgresVersion" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsStatusMinorVersionUpgrade" = {

      options = {
        "failure" = mkOption {
          description = "A failure message (when available)\n";
          type = (types.nullOr types.str);
        };
        "initialInstances" = mkOption {
          description = "The instances present when the operation started\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "pendingToRestartInstances" = mkOption {
          description = "The instances that are pending to be restarted\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "primaryInstance" = mkOption {
          description = "The primary instance when the operation started\n";
          type = (types.nullOr types.str);
        };
        "restartedInstances" = mkOption {
          description = "The instances that have been restarted\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "sourcePostgresVersion" = mkOption {
          description = "The postgres version currently used by the primary instance\n";
          type = (types.nullOr types.str);
        };
        "switchoverFinalized" = mkOption {
          description = "An ISO 8601 date indicating if and when the switchover finalized\n";
          type = (types.nullOr types.str);
        };
        "switchoverInitiated" = mkOption {
          description = "An ISO 8601 date indicating if and when the switchover initiated\n";
          type = (types.nullOr types.str);
        };
        "targetPostgresVersion" = mkOption {
          description = "The postgres version that the cluster will be upgraded (or downgraded) to\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "failure" = mkOverride 1002 null;
        "initialInstances" = mkOverride 1002 null;
        "pendingToRestartInstances" = mkOverride 1002 null;
        "primaryInstance" = mkOverride 1002 null;
        "restartedInstances" = mkOverride 1002 null;
        "sourcePostgresVersion" = mkOverride 1002 null;
        "switchoverFinalized" = mkOverride 1002 null;
        "switchoverInitiated" = mkOverride 1002 null;
        "targetPostgresVersion" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsStatusRestart" = {

      options = {
        "failure" = mkOption {
          description = "A failure message (when available)\n";
          type = (types.nullOr types.str);
        };
        "initialInstances" = mkOption {
          description = "The instances present when the operation started\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "pendingToRestartInstances" = mkOption {
          description = "The instances that are pending to be restarted\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "primaryInstance" = mkOption {
          description = "The primary instance when the operation started\n";
          type = (types.nullOr types.str);
        };
        "restartedInstances" = mkOption {
          description = "The instances that have been restarted\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "switchoverFinalized" = mkOption {
          description = "An ISO 8601 date indicating if and when the switchover finalized\n";
          type = (types.nullOr types.str);
        };
        "switchoverInitiated" = mkOption {
          description = "An ISO 8601 date indicating if and when the switchover initiated\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "failure" = mkOverride 1002 null;
        "initialInstances" = mkOverride 1002 null;
        "pendingToRestartInstances" = mkOverride 1002 null;
        "primaryInstance" = mkOverride 1002 null;
        "restartedInstances" = mkOverride 1002 null;
        "switchoverFinalized" = mkOverride 1002 null;
        "switchoverInitiated" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDbOpsStatusSecurityUpgrade" = {

      options = {
        "failure" = mkOption {
          description = "A failure message (when available)\n";
          type = (types.nullOr types.str);
        };
        "initialInstances" = mkOption {
          description = "The instances present when the operation started\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "pendingToRestartInstances" = mkOption {
          description = "The instances that are pending to be restarted\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "primaryInstance" = mkOption {
          description = "The primary instance when the operation started\n";
          type = (types.nullOr types.str);
        };
        "restartedInstances" = mkOption {
          description = "The instances that have been restarted\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "switchoverFinalized" = mkOption {
          description = "An ISO 8601 date indicating if and when the switchover finalized\n";
          type = (types.nullOr types.str);
        };
        "switchoverInitiated" = mkOption {
          description = "An ISO 8601 date indicating if and when the switchover initiated\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "failure" = mkOverride 1002 null;
        "initialInstances" = mkOverride 1002 null;
        "pendingToRestartInstances" = mkOverride 1002 null;
        "primaryInstance" = mkOverride 1002 null;
        "restartedInstances" = mkOverride 1002 null;
        "switchoverFinalized" = mkOverride 1002 null;
        "switchoverInitiated" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogs" = {

      options = {
        "apiVersion" = mkOption {
          description = "\nAPIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources\n";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "\nKind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds\n";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "";
          type = (submoduleOf "stackgres.io.v1.SGDistributedLogsSpec");
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDistributedLogsStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpec" = {

      options = {
        "configurations" = mkOption {
          description = "Cluster custom configurations.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDistributedLogsSpecConfigurations"));
        };
        "metadata" = mkOption {
          description = "Metadata information for cluster created resources.";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDistributedLogsSpecMetadata"));
        };
        "nonProductionOptions" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDistributedLogsSpecNonProductionOptions"));
        };
        "persistentVolume" = mkOption {
          description = "Pod's persistent volume configuration";
          type = (submoduleOf "stackgres.io.v1.SGDistributedLogsSpecPersistentVolume");
        };
        "postgresServices" = mkOption {
          description = "Kubernetes [services](https://kubernetes.io/docs/concepts/services-networking/service/) created or managed by StackGres.\n\n**Example:**\n\n```yaml\napiVersion: stackgres.io/v1\nkind: SGDistributedLogs\nmetadata:\n  name: stackgres\nspec:\n  postgresServices:\n    primary:\n      type: ClusterIP\n    replicas:\n      enabled: true\n      type: ClusterIP\n```\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDistributedLogsSpecPostgresServices"));
        };
        "profile" = mkOption {
          description = "The profile allow to change in a convenient place a set of configuration defaults that affect how the cluster is generated.\n\nAll those defaults can be overwritten by setting the correspoinding fields.\n\nAvailable profiles are:\n\n* `production`:\n\n  Prevents two Pods from running in the same Node (set `.spec.nonProductionOptions.disableClusterPodAntiAffinity` to `false` by default).\n  Sets both limits and requests using `SGInstanceProfile` for `patroni` container that runs both Patroni and Postgres (set `.spec.nonProductionOptions.disablePatroniResourceRequirements` to `false` by default).\n  Sets requests using the referenced `SGInstanceProfile` for sidecar containers other than `patroni` (set `.spec.nonProductionOptions.disableClusterResourceRequirements` to `false` by default).\n\n* `testing`:\n\n  Allows two Pods to running in the same Node (set `.spec.nonProductionOptions.disableClusterPodAntiAffinity` to `true` by default).\n  Sets both limits and requests using `SGInstanceProfile` for `patroni` container that runs both Patroni and Postgres (set `.spec.nonProductionOptions.disablePatroniResourceRequirements` to `false` by default).\n  Sets requests using the referenced `SGInstanceProfile` for sidecar containers other than `patroni` (set `.spec.nonProductionOptions.disableClusterResourceRequirements` to `false` by default).\n\n* `development`:\n\n  Allows two Pods from running in the same Node (set `.spec.nonProductionOptions.disableClusterPodAntiAffinity` to `true` by default).\n  Unset both limits and requests for `patroni` container that runs both Patroni and Postgres (set `.spec.nonProductionOptions.disablePatroniResourceRequirements` to `true` by default).\n  Unsets requests for sidecar containers other than `patroni` (set `.spec.nonProductionOptions.disableClusterResourceRequirements` to `true` by default).\n\n**Changing this field may require a restart.**\n";
          type = (types.nullOr types.str);
        };
        "resources" = mkOption {
          description = "Pod custom resources configuration.";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDistributedLogsSpecResources"));
        };
        "scheduling" = mkOption {
          description = "Pod custom scheduling and affinity configuration.\n\n**Changing this field may require a restart.**\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDistributedLogsSpecScheduling"));
        };
        "sgInstanceProfile" = mkOption {
          description = "Name of the [SGInstanceProfile](https://stackgres.io/doc/latest/04-postgres-cluster-management/03-resource-profiles/). A SGInstanceProfile defines CPU and memory limits. Must exist before creating a distributed logs. When no profile is set, a default (currently: 1 core, 2 GiB RAM) one is used.\n\n**Changing this field may require a restart.**\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "configurations" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "nonProductionOptions" = mkOverride 1002 null;
        "postgresServices" = mkOverride 1002 null;
        "profile" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
        "scheduling" = mkOverride 1002 null;
        "sgInstanceProfile" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpecConfigurations" = {

      options = {
        "sgPostgresConfig" = mkOption {
          description = "Name of the [SGPostgresConfig](https://stackgres.io/doc/latest/reference/crd/sgpgconfig) used for the distributed logs. It must exist. When not set, a default Postgres config, for the major version selected, is used.\n\n**Changing this field may require a restart.**\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "sgPostgresConfig" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpecMetadata" = {

      options = {
        "annotations" = mkOption {
          description = "Custom Kubernetes [annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) to be passed to resources created and managed by StackGres.\n\n**Example:**\n\n```yaml\napiVersion: stackgres.io/v1\nkind: SGDistributedLogs\nmetadata:\n  name: stackgres\nspec:\n  metadata:\n    annotations:\n      clusterPods:\n        key: value\n      primaryService:\n        key: value\n      replicasService:\n        key: value\n```\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDistributedLogsSpecMetadataAnnotations"));
        };
        "labels" = mkOption {
          description = "Custom Kubernetes [labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) to be passed to resources created and managed by StackGres.\n\n**Example:**\n\n```yaml\napiVersion: stackgres.io/v1\nkind: SGDistributedLogs\nmetadata:\n  name: stackgres\nspec:\n  metadata:\n    labels:\n      clusterPods:\n        customLabel: customLabelValue\n      services:\n        customLabel: customLabelValue\n```\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDistributedLogsSpecMetadataLabels"));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpecMetadataAnnotations" = {

      options = {
        "allResources" = mkOption {
          description = "Annotations to attach to any resource created or managed by StackGres.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "clusterPods" = mkOption {
          description = "Annotations to attach to pods created or managed by StackGres.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "pods" = mkOption {
          description = "**Deprecated** this field has been replaced by `clusterPods`.\n\nAnnotations to attach to pods created or managed by StackGres.\n";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "primaryService" = mkOption {
          description = "Custom Kubernetes [annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) passed to the `-primary` service.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "replicasService" = mkOption {
          description = "Custom Kubernetes [annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) passed to the `-replicas` service.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "services" = mkOption {
          description = "Annotations to attach to all services created or managed by StackGres.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "allResources" = mkOverride 1002 null;
        "clusterPods" = mkOverride 1002 null;
        "pods" = mkOverride 1002 null;
        "primaryService" = mkOverride 1002 null;
        "replicasService" = mkOverride 1002 null;
        "services" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpecMetadataLabels" = {

      options = {
        "clusterPods" = mkOption {
          description = "Labels to attach to Pods created or managed by StackGres.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "services" = mkOption {
          description = "Labels to attach to Services and Endpoints created or managed by StackGres.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "clusterPods" = mkOverride 1002 null;
        "services" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpecNonProductionOptions" = {

      options = {
        "disableClusterPodAntiAffinity" = mkOption {
          description = "It is a best practice, on non-containerized environments, when running production workloads, to run each database server on a different server (virtual or physical), i.e., not to co-locate more than one database server per host.\n\nThe same best practice applies to databases on containers. By default, StackGres will not allow to run more than one StackGres or Distributed Logs pod on a given Kubernetes node. If set to `true` it will allow more than one StackGres pod per node.\n\n**Changing this field may require a restart.**\n";
          type = (types.nullOr types.bool);
        };
        "disableClusterResourceRequirements" = mkOption {
          description = "It is a best practice, on containerized environments, when running production workloads, to enforce container's resources requirements.\n\nBy default, StackGres will configure resource requirements for all the containers. Set this property to true to prevent StackGres from setting container's resources requirements (except for patroni container, see `disablePatroniResourceRequirements`).\n\n**Changing this field may require a restart.**\n";
          type = (types.nullOr types.bool);
        };
        "disablePatroniResourceRequirements" = mkOption {
          description = "It is a best practice, on containerized environments, when running production workloads, to enforce container's resources requirements.\n\nThe same best practice applies to databases on containers. By default, StackGres will configure resource requirements for patroni container. Set this property to true to prevent StackGres from setting patroni container's resources requirement.\n\n**Changing this field may require a restart.**\n";
          type = (types.nullOr types.bool);
        };
        "enableSetClusterCpuRequests" = mkOption {
          description = "**Deprecated** this value is ignored and you can consider it as always `true`.\n\nOn containerized environments, when running production workloads, enforcing container's cpu requirements request to be equals to the limit allow to achieve the highest level of performance. Doing so, reduces the chances of leaving\n  the workload with less cpu than it requires. It also allow to set [static CPU management policy](https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/#static-policy) that allows to guarantee a pod the usage exclusive CPUs on the node.\n\nBy default, StackGres will configure cpu requirements to have the same limit and request for all the containers. Set this property to true to prevent StackGres from setting container's cpu requirements request equals to the limit (except for patroni container, see `enablePatroniCpuRequests`)\n  when `.spec.requests.containers.<container name>.cpu` `.spec.requests.initContainers.<container name>.cpu` is configured in the referenced `SGInstanceProfile`.\n\n**Changing this field may require a restart.**\n";
          type = (types.nullOr types.bool);
        };
        "enableSetClusterMemoryRequests" = mkOption {
          description = "**Deprecated** this value is ignored and you can consider it as always `true`.\n\nOn containerized environments, when running production workloads, enforcing container's memory requirements request to be equals to the limit allow to achieve the highest level of performance. Doing so, reduces the chances of leaving\n  the workload with less memory than it requires.\n\nBy default, StackGres will configure memory requirements to have the same limit and request for all the containers. Set this property to true to prevent StackGres from setting container's memory requirements request equals to the limit (except for patroni container, see `enablePatroniCpuRequests`)\n  when `.spec.requests.containers.<container name>.memory` `.spec.requests.initContainers.<container name>.memory` is configured in the referenced `SGInstanceProfile`.\n\n**Changing this field may require a restart.**\n";
          type = (types.nullOr types.bool);
        };
        "enableSetPatroniCpuRequests" = mkOption {
          description = "**Deprecated** this value is ignored and you can consider it as always `true`.\n\nOn containerized environments, when running production workloads, enforcing container's cpu requirements request to be equals to the limit allow to achieve the highest level of performance. Doing so, reduces the chances of leaving\n  the workload with less cpu than it requires. It also allow to set [static CPU management policy](https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/#static-policy) that allows to guarantee a pod the usage exclusive CPUs on the node.\n\nBy default, StackGres will configure cpu requirements to have the same limit and request for the patroni container. Set this property to true to prevent StackGres from setting patroni container's cpu requirements request equals to the limit\n  when `.spec.requests.cpu` is configured in the referenced `SGInstanceProfile`.\n\n**Changing this field may require a restart.**\n";
          type = (types.nullOr types.bool);
        };
        "enableSetPatroniMemoryRequests" = mkOption {
          description = "**Deprecated** this value is ignored and you can consider it as always `true`.\n\nOn containerized environments, when running production workloads, enforcing container's memory requirements request to be equals to the limit allow to achieve the highest level of performance. Doing so, reduces the chances of leaving\n  the workload with less memory than it requires.\n\nBy default, StackGres will configure memory requirements to have the same limit and request for the patroni container. Set this property to true to prevent StackGres from setting patroni container's memory requirements request equals to the limit\n  when `.spec.requests.memory` is configured in the referenced `SGInstanceProfile`.\n\n**Changing this field may require a restart.**\n";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "disableClusterPodAntiAffinity" = mkOverride 1002 null;
        "disableClusterResourceRequirements" = mkOverride 1002 null;
        "disablePatroniResourceRequirements" = mkOverride 1002 null;
        "enableSetClusterCpuRequests" = mkOverride 1002 null;
        "enableSetClusterMemoryRequests" = mkOverride 1002 null;
        "enableSetPatroniCpuRequests" = mkOverride 1002 null;
        "enableSetPatroniMemoryRequests" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpecPersistentVolume" = {

      options = {
        "size" = mkOption {
          description = "Size of the PersistentVolume set for the pod of the cluster for distributed logs. This size is specified either in Mebibytes, Gibibytes or Tebibytes (multiples of 2^20, 2^30 or 2^40, respectively).\n";
          type = (types.nullOr types.str);
        };
        "storageClass" = mkOption {
          description = "Name of an existing StorageClass in the Kubernetes cluster, used to create the PersistentVolumes for the instances of the cluster.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "size" = mkOverride 1002 null;
        "storageClass" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpecPostgresServices" = {

      options = {
        "primary" = mkOption {
          description = "Configuration for the `-primary` service. It provides a stable connection (regardless of primary failures or switchovers) to the read-write Postgres server of the cluster.";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDistributedLogsSpecPostgresServicesPrimary"));
        };
        "replicas" = mkOption {
          description = "Configuration for the `-replicas` service. It provides a stable connection (regardless of replica node failures) to any read-only Postgres server of the cluster. Read-only servers are load-balanced via this service.";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDistributedLogsSpecPostgresServicesReplicas"));
        };
      };

      config = {
        "primary" = mkOverride 1002 null;
        "replicas" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpecPostgresServicesPrimary" = {

      options = {
        "allocateLoadBalancerNodePorts" = mkOption {
          description = "allocateLoadBalancerNodePorts defines if NodePorts will be automatically allocated for services with type LoadBalancer.  Default is \"true\". It may be set to \"false\" if the cluster load-balancer does not rely on NodePorts.  If the caller requests specific NodePorts (by specifying a value), those requests will be respected, regardless of this field. This field may only be set for services with type LoadBalancer and will be cleared if the type is changed to any other type.";
          type = (types.nullOr types.bool);
        };
        "externalIPs" = mkOption {
          description = "externalIPs is a list of IP addresses for which nodes in the cluster will also accept traffic for this service.  These IPs are not managed by Kubernetes.  The user is responsible for ensuring that traffic arrives at a node with this IP.  A common example is external load-balancers that are not part of the Kubernetes system.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#allocateloadbalancernodeports-v1-core";
          type = (types.nullOr (types.listOf types.str));
        };
        "externalTrafficPolicy" = mkOption {
          description = "externalTrafficPolicy describes how nodes distribute service traffic they receive on one of the Service's \"externally-facing\" addresses (NodePorts, ExternalIPs, and LoadBalancer IPs). If set to \"Local\", the proxy will configure the service in a way that assumes that external load balancers will take care of balancing the service traffic between nodes, and so each node will deliver traffic only to the node-local endpoints of the service, without masquerading the client source IP. (Traffic mistakenly sent to a node with no endpoints will be dropped.) The default value, \"Cluster\", uses the standard behavior of routing to all endpoints evenly (possibly modified by topology and other features). Note that traffic sent to an External IP or LoadBalancer IP from within the cluster will always get \"Cluster\" semantics, but clients sending to a NodePort from within the cluster may need to take traffic policy into account when picking a node.";
          type = (types.nullOr types.str);
        };
        "healthCheckNodePort" = mkOption {
          description = "healthCheckNodePort specifies the healthcheck nodePort for the service. This only applies when type is set to LoadBalancer and externalTrafficPolicy is set to Local. If a value is specified, is in-range, and is not in use, it will be used.  If not specified, a value will be automatically allocated.  External systems (e.g. load-balancers) can use this port to determine if a given node holds endpoints for this service or not.  If this field is specified when creating a Service which does not need it, creation will fail. This field will be wiped when updating a Service to no longer need it (e.g. changing type). This field cannot be updated once set.";
          type = (types.nullOr types.int);
        };
        "internalTrafficPolicy" = mkOption {
          description = "InternalTrafficPolicy describes how nodes distribute service traffic they receive on the ClusterIP. If set to \"Local\", the proxy will assume that pods only want to talk to endpoints of the service on the same node as the pod, dropping the traffic if there are no local endpoints. The default value, \"Cluster\", uses the standard behavior of routing to all endpoints evenly (possibly modified by topology and other features).";
          type = (types.nullOr types.str);
        };
        "ipFamilies" = mkOption {
          description = "IPFamilies is a list of IP families (e.g. IPv4, IPv6) assigned to this service. This field is usually assigned automatically based on cluster configuration and the ipFamilyPolicy field. If this field is specified manually, the requested family is available in the cluster, and ipFamilyPolicy allows it, it will be used; otherwise creation of the service will fail. This field is conditionally mutable: it allows for adding or removing a secondary IP family, but it does not allow changing the primary IP family of the Service. Valid values are \"IPv4\" and \"IPv6\".  This field only applies to Services of types ClusterIP, NodePort, and LoadBalancer, and does apply to \"headless\" services. This field will be wiped when updating a Service to type ExternalName.\n\nThis field may hold a maximum of two entries (dual-stack families, in either order).  These families must correspond to the values of the clusterIPs field, if specified. Both clusterIPs and ipFamilies are governed by the ipFamilyPolicy field.";
          type = (types.nullOr (types.listOf types.str));
        };
        "ipFamilyPolicy" = mkOption {
          description = "IPFamilyPolicy represents the dual-stack-ness requested or required by this Service. If there is no value provided, then this field will be set to SingleStack. Services can be \"SingleStack\" (a single IP family), \"PreferDualStack\" (two IP families on dual-stack configured clusters or a single IP family on single-stack clusters), or \"RequireDualStack\" (two IP families on dual-stack configured clusters, otherwise fail). The ipFamilies and clusterIPs fields depend on the value of this field. This field will be wiped when updating a service to type ExternalName.";
          type = (types.nullOr types.str);
        };
        "loadBalancerClass" = mkOption {
          description = "loadBalancerClass is the class of the load balancer implementation this Service belongs to. If specified, the value of this field must be a label-style identifier, with an optional prefix, e.g. \"internal-vip\" or \"example.com/internal-vip\". Unprefixed names are reserved for end-users. This field can only be set when the Service type is 'LoadBalancer'. If not set, the default load balancer implementation is used, today this is typically done through the cloud provider integration, but should apply for any default implementation. If set, it is assumed that a load balancer implementation is watching for Services with a matching class. Any default load balancer implementation (e.g. cloud providers) should ignore Services that set this field. This field can only be set when creating or updating a Service to type 'LoadBalancer'. Once set, it can not be changed. This field will be wiped when a service is updated to a non 'LoadBalancer' type.";
          type = (types.nullOr types.str);
        };
        "loadBalancerIP" = mkOption {
          description = "Only applies to Service Type: LoadBalancer. This feature depends on whether the underlying cloud-provider supports specifying the loadBalancerIP when a load balancer is created. This field will be ignored if the cloud-provider does not support the feature. Deprecated: This field was under-specified and its meaning varies across implementations. Using it is non-portable and it may not support dual-stack. Users are encouraged to use implementation-specific annotations when available.";
          type = (types.nullOr types.str);
        };
        "loadBalancerSourceRanges" = mkOption {
          description = "If specified and supported by the platform, this will restrict traffic through the cloud-provider load-balancer will be restricted to the specified client IPs. This field will be ignored if the cloud-provider does not support the feature.\" More info: https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/";
          type = (types.nullOr (types.listOf types.str));
        };
        "nodePorts" = mkOption {
          description = "nodePorts is a list of ports for exposing a cluster services to the outside world";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1.SGDistributedLogsSpecPostgresServicesPrimaryNodePorts")
          );
        };
        "publishNotReadyAddresses" = mkOption {
          description = "publishNotReadyAddresses indicates that any agent which deals with endpoints for this Service should disregard any indications of ready/not-ready. The primary use case for setting this field is for a StatefulSet's Headless Service to propagate SRV DNS records for its Pods for the purpose of peer discovery. The Kubernetes controllers that generate Endpoints and EndpointSlice resources for Services interpret this to mean that all endpoints are considered \"ready\" even if the Pods themselves are not. Agents which consume only Kubernetes generated endpoints through the Endpoints or EndpointSlice resources can safely assume this behavior.";
          type = (types.nullOr types.bool);
        };
        "sessionAffinity" = mkOption {
          description = "Supports \"ClientIP\" and \"None\". Used to maintain session affinity. Enable client IP based session affinity. Must be ClientIP or None. Defaults to None. More info: https://kubernetes.io/docs/concepts/services-networking/service/#virtual-ips-and-service-proxies";
          type = (types.nullOr types.str);
        };
        "sessionAffinityConfig" = mkOption {
          description = "SessionAffinityConfig represents the configurations of session affinity.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#sessionaffinityconfig-v1-core";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGDistributedLogsSpecPostgresServicesPrimarySessionAffinityConfig"
            )
          );
        };
        "type" = mkOption {
          description = "type determines how the Service is exposed. Defaults to ClusterIP. Valid\noptions are ClusterIP, NodePort, LoadBalancer and None. \"ClusterIP\" allocates\na cluster-internal IP address for load-balancing to endpoints.\n\"NodePort\" builds on ClusterIP and allocates a port on every node.\n\"LoadBalancer\" builds on NodePort and creates\nan external load-balancer (if supported in the current cloud).\n\"None\" creates an headless service that can be use in conjunction with `.spec.pods.disableEnvoy`\n set to `true` in order to acces the database using a DNS.\nMore info:\n* https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types\n* https://kubernetes.io/docs/concepts/services-networking/service/#headless-services\n* https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "allocateLoadBalancerNodePorts" = mkOverride 1002 null;
        "externalIPs" = mkOverride 1002 null;
        "externalTrafficPolicy" = mkOverride 1002 null;
        "healthCheckNodePort" = mkOverride 1002 null;
        "internalTrafficPolicy" = mkOverride 1002 null;
        "ipFamilies" = mkOverride 1002 null;
        "ipFamilyPolicy" = mkOverride 1002 null;
        "loadBalancerClass" = mkOverride 1002 null;
        "loadBalancerIP" = mkOverride 1002 null;
        "loadBalancerSourceRanges" = mkOverride 1002 null;
        "nodePorts" = mkOverride 1002 null;
        "publishNotReadyAddresses" = mkOverride 1002 null;
        "sessionAffinity" = mkOverride 1002 null;
        "sessionAffinityConfig" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpecPostgresServicesPrimaryNodePorts" = {

      options = {
        "pgport" = mkOption {
          description = "the node port that will be exposed to connect to Postgres instance";
          type = (types.nullOr types.int);
        };
        "replicationport" = mkOption {
          description = "the node port that will be exposed to connect to Postgres instance for replication purpose";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "pgport" = mkOverride 1002 null;
        "replicationport" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpecPostgresServicesPrimarySessionAffinityConfig" = {

      options = {
        "clientIP" = mkOption {
          description = "ClientIPConfig represents the configurations of Client IP based session affinity.";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGDistributedLogsSpecPostgresServicesPrimarySessionAffinityConfigClientIP"
            )
          );
        };
      };

      config = {
        "clientIP" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpecPostgresServicesPrimarySessionAffinityConfigClientIP" = {

      options = {
        "timeoutSeconds" = mkOption {
          description = "timeoutSeconds specifies the seconds of ClientIP type session sticky time. The value must be >0 && <=86400(for 1 day) if ServiceAffinity == \"ClientIP\". Default value is 10800(for 3 hours).";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "timeoutSeconds" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpecPostgresServicesReplicas" = {

      options = {
        "allocateLoadBalancerNodePorts" = mkOption {
          description = "allocateLoadBalancerNodePorts defines if NodePorts will be automatically allocated for services with type LoadBalancer.  Default is \"true\". It may be set to \"false\" if the cluster load-balancer does not rely on NodePorts.  If the caller requests specific NodePorts (by specifying a value), those requests will be respected, regardless of this field. This field may only be set for services with type LoadBalancer and will be cleared if the type is changed to any other type.";
          type = (types.nullOr types.bool);
        };
        "enabled" = mkOption {
          description = "Specify if the `-replicas` service should be created or not.";
          type = (types.nullOr types.bool);
        };
        "externalIPs" = mkOption {
          description = "externalIPs is a list of IP addresses for which nodes in the cluster will also accept traffic for this service.  These IPs are not managed by Kubernetes.  The user is responsible for ensuring that traffic arrives at a node with this IP.  A common example is external load-balancers that are not part of the Kubernetes system.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#allocateloadbalancernodeports-v1-core";
          type = (types.nullOr (types.listOf types.str));
        };
        "externalTrafficPolicy" = mkOption {
          description = "externalTrafficPolicy describes how nodes distribute service traffic they receive on one of the Service's \"externally-facing\" addresses (NodePorts, ExternalIPs, and LoadBalancer IPs). If set to \"Local\", the proxy will configure the service in a way that assumes that external load balancers will take care of balancing the service traffic between nodes, and so each node will deliver traffic only to the node-local endpoints of the service, without masquerading the client source IP. (Traffic mistakenly sent to a node with no endpoints will be dropped.) The default value, \"Cluster\", uses the standard behavior of routing to all endpoints evenly (possibly modified by topology and other features). Note that traffic sent to an External IP or LoadBalancer IP from within the cluster will always get \"Cluster\" semantics, but clients sending to a NodePort from within the cluster may need to take traffic policy into account when picking a node.";
          type = (types.nullOr types.str);
        };
        "healthCheckNodePort" = mkOption {
          description = "healthCheckNodePort specifies the healthcheck nodePort for the service. This only applies when type is set to LoadBalancer and externalTrafficPolicy is set to Local. If a value is specified, is in-range, and is not in use, it will be used.  If not specified, a value will be automatically allocated.  External systems (e.g. load-balancers) can use this port to determine if a given node holds endpoints for this service or not.  If this field is specified when creating a Service which does not need it, creation will fail. This field will be wiped when updating a Service to no longer need it (e.g. changing type). This field cannot be updated once set.";
          type = (types.nullOr types.int);
        };
        "internalTrafficPolicy" = mkOption {
          description = "InternalTrafficPolicy describes how nodes distribute service traffic they receive on the ClusterIP. If set to \"Local\", the proxy will assume that pods only want to talk to endpoints of the service on the same node as the pod, dropping the traffic if there are no local endpoints. The default value, \"Cluster\", uses the standard behavior of routing to all endpoints evenly (possibly modified by topology and other features).";
          type = (types.nullOr types.str);
        };
        "ipFamilies" = mkOption {
          description = "IPFamilies is a list of IP families (e.g. IPv4, IPv6) assigned to this service. This field is usually assigned automatically based on cluster configuration and the ipFamilyPolicy field. If this field is specified manually, the requested family is available in the cluster, and ipFamilyPolicy allows it, it will be used; otherwise creation of the service will fail. This field is conditionally mutable: it allows for adding or removing a secondary IP family, but it does not allow changing the primary IP family of the Service. Valid values are \"IPv4\" and \"IPv6\".  This field only applies to Services of types ClusterIP, NodePort, and LoadBalancer, and does apply to \"headless\" services. This field will be wiped when updating a Service to type ExternalName.\n\nThis field may hold a maximum of two entries (dual-stack families, in either order).  These families must correspond to the values of the clusterIPs field, if specified. Both clusterIPs and ipFamilies are governed by the ipFamilyPolicy field.";
          type = (types.nullOr (types.listOf types.str));
        };
        "ipFamilyPolicy" = mkOption {
          description = "IPFamilyPolicy represents the dual-stack-ness requested or required by this Service. If there is no value provided, then this field will be set to SingleStack. Services can be \"SingleStack\" (a single IP family), \"PreferDualStack\" (two IP families on dual-stack configured clusters or a single IP family on single-stack clusters), or \"RequireDualStack\" (two IP families on dual-stack configured clusters, otherwise fail). The ipFamilies and clusterIPs fields depend on the value of this field. This field will be wiped when updating a service to type ExternalName.";
          type = (types.nullOr types.str);
        };
        "loadBalancerClass" = mkOption {
          description = "loadBalancerClass is the class of the load balancer implementation this Service belongs to. If specified, the value of this field must be a label-style identifier, with an optional prefix, e.g. \"internal-vip\" or \"example.com/internal-vip\". Unprefixed names are reserved for end-users. This field can only be set when the Service type is 'LoadBalancer'. If not set, the default load balancer implementation is used, today this is typically done through the cloud provider integration, but should apply for any default implementation. If set, it is assumed that a load balancer implementation is watching for Services with a matching class. Any default load balancer implementation (e.g. cloud providers) should ignore Services that set this field. This field can only be set when creating or updating a Service to type 'LoadBalancer'. Once set, it can not be changed. This field will be wiped when a service is updated to a non 'LoadBalancer' type.";
          type = (types.nullOr types.str);
        };
        "loadBalancerIP" = mkOption {
          description = "Only applies to Service Type: LoadBalancer. This feature depends on whether the underlying cloud-provider supports specifying the loadBalancerIP when a load balancer is created. This field will be ignored if the cloud-provider does not support the feature. Deprecated: This field was under-specified and its meaning varies across implementations. Using it is non-portable and it may not support dual-stack. Users are encouraged to use implementation-specific annotations when available.";
          type = (types.nullOr types.str);
        };
        "loadBalancerSourceRanges" = mkOption {
          description = "If specified and supported by the platform, this will restrict traffic through the cloud-provider load-balancer will be restricted to the specified client IPs. This field will be ignored if the cloud-provider does not support the feature.\" More info: https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/";
          type = (types.nullOr (types.listOf types.str));
        };
        "nodePorts" = mkOption {
          description = "nodePorts is a list of ports for exposing a cluster services to the outside world";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1.SGDistributedLogsSpecPostgresServicesReplicasNodePorts")
          );
        };
        "publishNotReadyAddresses" = mkOption {
          description = "publishNotReadyAddresses indicates that any agent which deals with endpoints for this Service should disregard any indications of ready/not-ready. The primary use case for setting this field is for a StatefulSet's Headless Service to propagate SRV DNS records for its Pods for the purpose of peer discovery. The Kubernetes controllers that generate Endpoints and EndpointSlice resources for Services interpret this to mean that all endpoints are considered \"ready\" even if the Pods themselves are not. Agents which consume only Kubernetes generated endpoints through the Endpoints or EndpointSlice resources can safely assume this behavior.";
          type = (types.nullOr types.bool);
        };
        "sessionAffinity" = mkOption {
          description = "Supports \"ClientIP\" and \"None\". Used to maintain session affinity. Enable client IP based session affinity. Must be ClientIP or None. Defaults to None. More info: https://kubernetes.io/docs/concepts/services-networking/service/#virtual-ips-and-service-proxies";
          type = (types.nullOr types.str);
        };
        "sessionAffinityConfig" = mkOption {
          description = "SessionAffinityConfig represents the configurations of session affinity.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#sessionaffinityconfig-v1-core";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGDistributedLogsSpecPostgresServicesReplicasSessionAffinityConfig"
            )
          );
        };
        "type" = mkOption {
          description = "type determines how the Service is exposed. Defaults to ClusterIP. Valid\noptions are ClusterIP, NodePort, LoadBalancer and None. \"ClusterIP\" allocates\na cluster-internal IP address for load-balancing to endpoints.\n\"NodePort\" builds on ClusterIP and allocates a port on every node.\n\"LoadBalancer\" builds on NodePort and creates\nan external load-balancer (if supported in the current cloud).\n\"None\" creates an headless service that can be use in conjunction with `.spec.pods.disableEnvoy`\n set to `true` in order to acces the database using a DNS.\nMore info:\n* https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types\n* https://kubernetes.io/docs/concepts/services-networking/service/#headless-services\n* https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "allocateLoadBalancerNodePorts" = mkOverride 1002 null;
        "enabled" = mkOverride 1002 null;
        "externalIPs" = mkOverride 1002 null;
        "externalTrafficPolicy" = mkOverride 1002 null;
        "healthCheckNodePort" = mkOverride 1002 null;
        "internalTrafficPolicy" = mkOverride 1002 null;
        "ipFamilies" = mkOverride 1002 null;
        "ipFamilyPolicy" = mkOverride 1002 null;
        "loadBalancerClass" = mkOverride 1002 null;
        "loadBalancerIP" = mkOverride 1002 null;
        "loadBalancerSourceRanges" = mkOverride 1002 null;
        "nodePorts" = mkOverride 1002 null;
        "publishNotReadyAddresses" = mkOverride 1002 null;
        "sessionAffinity" = mkOverride 1002 null;
        "sessionAffinityConfig" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpecPostgresServicesReplicasNodePorts" = {

      options = {
        "pgport" = mkOption {
          description = "the node port that will be exposed to connect to Postgres instance";
          type = (types.nullOr types.int);
        };
        "replicationport" = mkOption {
          description = "the node port that will be exposed to connect to Postgres instance for replication purpose";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "pgport" = mkOverride 1002 null;
        "replicationport" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpecPostgresServicesReplicasSessionAffinityConfig" = {

      options = {
        "clientIP" = mkOption {
          description = "ClientIPConfig represents the configurations of Client IP based session affinity.";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGDistributedLogsSpecPostgresServicesPrimarySessionAffinityConfigClientIP"
            )
          );
        };
      };

      config = {
        "clientIP" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpecResources" = {

      options = {
        "disableResourcesRequestsSplitFromTotal" = mkOption {
          description = "When set to `true` the resources requests values in fields `SGInstanceProfile.spec.requests.cpu` and `SGInstanceProfile.spec.requests.memory` will represent the resources\n requests of the patroni container and the total resources requests calculated by adding the resources requests of all the containers (including the patroni container).\n\n**Changing this field may require a restart.**\n";
          type = (types.nullOr types.bool);
        };
        "enableClusterLimitsRequirements" = mkOption {
          description = "When set to `true` resources limits for containers other than the patroni container wil be set just like for patroni contianer as specified in the SGInstanceProfile.\n\n**Changing this field may require a restart.**\n";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "disableResourcesRequestsSplitFromTotal" = mkOverride 1002 null;
        "enableClusterLimitsRequirements" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpecScheduling" = {

      options = {
        "nodeAffinity" = mkOption {
          description = "Node affinity is a group of node affinity scheduling rules.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#nodeaffinity-v1-core";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingNodeAffinity"));
        };
        "nodeSelector" = mkOption {
          description = "NodeSelector is a selector which must be true for the pod to fit on a node. Selector which must match a node's labels for the pod to be scheduled on that node. More info: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/\n";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "podAffinity" = mkOption {
          description = "Pod affinity is a group of inter pod affinity scheduling rules.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#podaffinity-v1-core";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinity"));
        };
        "podAntiAffinity" = mkOption {
          description = "Pod anti affinity is a group of inter pod anti affinity scheduling rules.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#podantiaffinity-v1-core";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinity")
          );
        };
        "priorityClassName" = mkOption {
          description = "If specified, indicates the pod's priority. \"system-node-critical\" and \"system-cluster-critical\" are two special keywords which indicate the highest priorities with the former being the highest priority. Any other name must be defined by creating a PriorityClass object with that name. If not specified, the pod priority will be default or zero if there is no default.";
          type = (types.nullOr types.str);
        };
        "tolerations" = mkOption {
          description = "If specified, the pod's tolerations.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#toleration-v1-core";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingTolerations")
            )
          );
        };
      };

      config = {
        "nodeAffinity" = mkOverride 1002 null;
        "nodeSelector" = mkOverride 1002 null;
        "podAffinity" = mkOverride 1002 null;
        "podAntiAffinity" = mkOverride 1002 null;
        "priorityClassName" = mkOverride 1002 null;
        "tolerations" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingNodeAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy the affinity expressions specified by this field, but it may choose a node that violates one or more of the expressions. The node that is most preferred is the one with the greatest sum of weights, i.e. for each node that meets all of the scheduling requirements (resource request, requiredDuringScheduling affinity expressions, etc.), compute a sum by iterating through the elements of this field and adding \"weight\" to the sum if the node matches the corresponding matchExpressions; the node(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "A node selector represents the union of the results of one or more label queries over a set of nodes; that is, it represents the OR of the selectors represented by the node selector terms.";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution"
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "preference" = mkOption {
            description = "A null or empty node selector term matches no objects. The requirements of them are ANDed. The TopologySelectorTerm type implements a subset of the NodeSelectorTerm.";
            type = (
              submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference"
            );
          };
          "weight" = mkOption {
            description = "Weight associated with matching the corresponding nodeSelectorTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields"
                )
              )
            );
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchFields" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "nodeSelectorTerms" = mkOption {
            description = "Required. A list of node selector terms. The terms are ORed.";
            type = (
              types.listOf (
                submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms"
              )
            );
          };
        };

        config = { };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields"
                )
              )
            );
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchFields" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy the affinity expressions specified by this field, but it may choose a node that violates one or more of the expressions. The node that is most preferred is the one with the greatest sum of weights, i.e. for each node that meets all of the scheduling requirements (resource request, requiredDuringScheduling affinity expressions, etc.), compute a sum by iterating through the elements of this field and adding \"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the node(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at scheduling time, the pod will not be scheduled onto the node. If the affinity requirements specified by this field cease to be met at some point during pod execution (e.g. due to a pod label update), the system may or may not try to eventually evict the pod from its node. When there are multiple elements, the lists of nodes corresponding to each podAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Defines a set of pods (namely those matching the labelSelector relative to the given namespace(s)) that this pod should be co-located (affinity) or not co-located (anti-affinity) with, where co-located is defined as running on a node whose value of the label with key <topologyKey> matches that of any node on which a pod of the set of pods is running";
            type = (
              submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both matchLabelKeys and labelSelector. Also, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both mismatchLabelKeys and labelSelector. Also, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both matchLabelKeys and labelSelector. Also, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both mismatchLabelKeys and labelSelector. Also, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy the anti-affinity expressions specified by this field, but it may choose a node that violates one or more of the expressions. The node that is most preferred is the one with the greatest sum of weights, i.e. for each node that meets all of the scheduling requirements (resource request, requiredDuringScheduling anti-affinity expressions, etc.), compute a sum by iterating through the elements of this field and adding \"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the node(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the anti-affinity requirements specified by this field are not met at scheduling time, the pod will not be scheduled onto the node. If the anti-affinity requirements specified by this field cease to be met at some point during pod execution (e.g. due to a pod label update), the system may or may not try to eventually evict the pod from its node. When there are multiple elements, the lists of nodes corresponding to each podAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Defines a set of pods (namely those matching the labelSelector relative to the given namespace(s)) that this pod should be co-located (affinity) or not co-located (anti-affinity) with, where co-located is defined as running on a node whose value of the label with key <topologyKey> matches that of any node on which a pod of the set of pods is running";
            type = (
              submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both matchLabelKeys and labelSelector. Also, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both mismatchLabelKeys and labelSelector. Also, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both matchLabelKeys and labelSelector. Also, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both mismatchLabelKeys and labelSelector. Also, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGDistributedLogsSpecSchedulingTolerations" = {

      options = {
        "effect" = mkOption {
          description = "Effect indicates the taint effect to match. Empty means match all taint effects. When specified, allowed values are NoSchedule, PreferNoSchedule and NoExecute.";
          type = (types.nullOr types.str);
        };
        "key" = mkOption {
          description = "Key is the taint key that the toleration applies to. Empty means match all taint keys. If the key is empty, operator must be Exists; this combination means to match all values and all keys.";
          type = (types.nullOr types.str);
        };
        "operator" = mkOption {
          description = "Operator represents a key's relationship to the value. Valid operators are Exists and Equal. Defaults to Equal. Exists is equivalent to wildcard for value, so that a pod can tolerate all taints of a particular category.";
          type = (types.nullOr types.str);
        };
        "tolerationSeconds" = mkOption {
          description = "TolerationSeconds represents the period of time the toleration (which must be of effect NoExecute, otherwise this field is ignored) tolerates the taint. By default, it is not set, which means tolerate the taint forever (do not evict). Zero and negative values will be treated as 0 (evict immediately) by the system.";
          type = (types.nullOr types.int);
        };
        "value" = mkOption {
          description = "Value is the taint value the toleration matches to. If the operator is Exists, the value should be empty, otherwise just a regular string.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "effect" = mkOverride 1002 null;
        "key" = mkOverride 1002 null;
        "operator" = mkOverride 1002 null;
        "tolerationSeconds" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsStatus" = {

      options = {
        "conditions" = mkOption {
          description = "";
          type = (
            types.nullOr (types.listOf (submoduleOf "stackgres.io.v1.SGDistributedLogsStatusConditions"))
          );
        };
        "connectedClusters" = mkOption {
          description = "The list of connected `sgclusters`";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "stackgres.io.v1.SGDistributedLogsStatusConnectedClusters" "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "databases" = mkOption {
          description = "The list of database status";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "stackgres.io.v1.SGDistributedLogsStatusDatabases" "name" [ ]
            )
          );
          apply = attrsToList;
        };
        "fluentdConfigHash" = mkOption {
          description = "The hash of the configuration file that is used by fluentd";
          type = (types.nullOr types.str);
        };
        "labelPrefix" = mkOption {
          description = "The custom prefix that is prepended to all labels.";
          type = (types.nullOr types.str);
        };
        "oldConfigMapRemoved" = mkOption {
          description = "Flag to indicate the previous existing ConfigMap has been removed.";
          type = (types.nullOr types.bool);
        };
        "postgresVersion" = mkOption {
          description = "The used Postgres version";
          type = (types.nullOr types.str);
        };
        "timescaledbVersion" = mkOption {
          description = "The used Timescaledb version";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "connectedClusters" = mkOverride 1002 null;
        "databases" = mkOverride 1002 null;
        "fluentdConfigHash" = mkOverride 1002 null;
        "labelPrefix" = mkOverride 1002 null;
        "oldConfigMapRemoved" = mkOverride 1002 null;
        "postgresVersion" = mkOverride 1002 null;
        "timescaledbVersion" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "Last time the condition transitioned from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "A human readable message indicating details about the transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "The reason for the condition's last transition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "Status of the condition, one of True, False, Unknown.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "Type of deployment condition.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsStatusConnectedClusters" = {

      options = {
        "config" = mkOption {
          description = "The configuration for `sgdistributedlgos` of this `sgcluster`";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1.SGDistributedLogsStatusConnectedClustersConfig")
          );
        };
        "name" = mkOption {
          description = "The `sgcluster` name";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The `sgcluster` namespace";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "config" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsStatusConnectedClustersConfig" = {

      options = {
        "retention" = mkOption {
          description = "The retention window that has been applied to tables";
          type = (types.nullOr types.str);
        };
        "sgDistributedLogs" = mkOption {
          description = "The `sgdistributedlogs` to which this `sgcluster` is connected to";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "retention" = mkOverride 1002 null;
        "sgDistributedLogs" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGDistributedLogsStatusDatabases" = {

      options = {
        "name" = mkOption {
          description = "The database name that has been created";
          type = (types.nullOr types.str);
        };
        "retention" = mkOption {
          description = "The retention window that has been applied to tables";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "retention" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGInstanceProfile" = {

      options = {
        "apiVersion" = mkOption {
          description = "\nAPIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources\n";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "\nKind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds\n";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "";
          type = (submoduleOf "stackgres.io.v1.SGInstanceProfileSpec");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGInstanceProfileSpec" = {

      options = {
        "containers" = mkOption {
          description = "The CPU(s) (cores) and RAM limits assigned to containers other than patroni container.\n";
          type = (types.nullOr (types.attrsOf types.attrs));
        };
        "cpu" = mkOption {
          description = "CPU(s) (cores) limits for every resource's Pod that reference this SGInstanceProfile. The suffix `m`\n  specifies millicpus (where 1000m is equals to 1).\n\nThe number of cpu limits is assigned to the patroni container (that runs both Patroni and PostgreSQL).\n\nA minimum of 2 cpu is recommended.\n";
          type = (types.nullOr types.str);
        };
        "hugePages" = mkOption {
          description = "RAM limits allocated for huge pages of the patroni container (that runs both Patroni and PostgreSQL).\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGInstanceProfileSpecHugePages"));
        };
        "initContainers" = mkOption {
          description = "The CPU(s) (cores) and RAM limits assigned to the init containers.";
          type = (types.nullOr (types.attrsOf types.attrs));
        };
        "memory" = mkOption {
          description = "RAM limits for every resource's Pod that reference this SGInstanceProfile. The suffix `Mi` or `Gi`\n  specifies Mebibytes or Gibibytes, respectively.\n\nThe amount of RAM limits is assigned to the patroni container (that runs both Patroni and PostgreSQL).\n\nA minimum of 2Gi is recommended.\n";
          type = (types.nullOr types.str);
        };
        "requests" = mkOption {
          description = "This section allow to configure the resources requests for each container and, if not specified, it is filled with some defaults based on the fields `.spec.cpu` and `.spec.memory` will be set.\n\nOn containerized environments, when running production workloads, enforcing container's resources requirements requests to be equals to the limits in order to achieve the highest level of performance. Doing so, reduces the chances of leaving\n the workload with less resources than it requires. It also allow to set [static CPU management policy](https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/#static-policy) that allows to guarantee a pod the usage exclusive CPUs on the node.\n There are cases where you may need to set cpu requests to the same value as cpu limits in order to achieve static CPU management policy.\n\nBy default the resources requests values in fields `.spec.requests.cpu` and `.spec.requests.memory` represent the total resources requests assigned to each resource's Pod that reference this SGInstanceProfile.\n The resources requests of the patroni container (that runs both Patroni and PostgreSQL) is calculated by subtracting from the total resources requests the resources requests of other containers that are present in the Pod.\n To change this behavior and having the resources requests values in fields `.spec.requests.cpu` and `.spec.requests.memory` to represent the resources requests of the patroni container and the total resources requests\n calculated by adding the resources requests of all the containers (including the patroni container) you may set one or more of the following fields to `true`\n (depending on the resource's Pods you need this behaviour to be changed):\n \n* `SGCluster.spec.pods.resources.disableResourcesRequestsSplitFromTotal`\n* `SGShardedCluster.spec.coordinator.pods.resources.disableResourcesRequestsSplitFromTotal`\n* `SGShardedCluster.spec.shards.pods.resources.disableResourcesRequestsSplitFromTotal`\n* `SGShardedCluster.spec.shards.ovewrites.pods.resources.disableResourcesRequestsSplitFromTotal`\n* `SGDistributedLogs.spec.resources.disableResourcesRequestsSplitFromTotal`\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGInstanceProfileSpecRequests"));
        };
      };

      config = {
        "containers" = mkOverride 1002 null;
        "cpu" = mkOverride 1002 null;
        "hugePages" = mkOverride 1002 null;
        "initContainers" = mkOverride 1002 null;
        "memory" = mkOverride 1002 null;
        "requests" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGInstanceProfileSpecHugePages" = {

      options = {
        "hugepages-1Gi" = mkOption {
          description = "RAM limits allocated for huge pages of the patroni container (that runs both Patroni and PostgreSQL) with a size of 1Gi. The suffix `Mi` or `Gi`\n  specifies Mebibytes or Gibibytes, respectively.\n";
          type = (types.nullOr types.str);
        };
        "hugepages-2Mi" = mkOption {
          description = "RAM limits allocated for huge pages of the patroni container (that runs both Patroni and PostgreSQL) with a size of 2Mi. The suffix `Mi` or `Gi`\n  specifies Mebibytes or Gibibytes, respectively.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "hugepages-1Gi" = mkOverride 1002 null;
        "hugepages-2Mi" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGInstanceProfileSpecRequests" = {

      options = {
        "containers" = mkOption {
          description = "The CPU(s) (cores) and RAM requests assigned to containers other than patroni container.\n";
          type = (types.nullOr (types.attrsOf types.attrs));
        };
        "cpu" = mkOption {
          description = "CPU(s) (cores) requests for every resource's Pod that reference this SGInstanceProfile. The suffix `m`\n  specifies millicpus (where 1000m is equals to 1).\n\nBy default the cpu requests values in field `.spec.requests.cpu` represent the total cpu requests assigned to each resource's Pod that reference this SGInstanceProfile.\n The cpu requests of the patroni container (that runs both Patroni and PostgreSQL) is calculated by subtracting from the total cpu requests the cpu requests of other containers that are present in the Pod.\n To change this behavior and having the cpu requests values in field `.spec.requests.cpu` to represent the cpu requests of the patroni container and the total cpu requests\n calculated by adding the cpu requests of all the containers (including the patroni container) you may set one or more of the following fields to `true`\n (depending on the resource's Pods you need this behaviour to be changed):\n \n* `SGCluster.spec.pods.resources.disableResourcesRequestsSplitFromTotal`\n* `SGShardedCluster.spec.coordinator.pods.resources.disableResourcesRequestsSplitFromTotal`\n* `SGShardedCluster.spec.shards.pods.resources.disableResourcesRequestsSplitFromTotal`\n* `SGShardedCluster.spec.shards.ovewrites.pods.resources.disableResourcesRequestsSplitFromTotal`\n* `SGDistributedLogs.spec.resources.disableResourcesRequestsSplitFromTotal`\n";
          type = (types.nullOr types.str);
        };
        "initContainers" = mkOption {
          description = "The CPU(s) (cores) and RAM requests assigned to init containers.";
          type = (types.nullOr (types.attrsOf types.attrs));
        };
        "memory" = mkOption {
          description = "RAM requests for every resource's Pod that reference this SGInstanceProfile. The suffix `Mi` or `Gi`\n  specifies Mebibytes or Gibibytes, respectively.\n\nBy default the memory requests values in field `.spec.requests.memory` represent the total memory requests assigned to each resource's Pod that reference this SGInstanceProfile.\n The memory requests of the patroni container (that runs both Patroni and PostgreSQL) is calculated by subtracting from the total memory requests the memory requests of other containers that are present in the Pod.\n To change this behavior and having the memory requests values in field `.spec.requests.memory` to represent the memory requests of the patroni container and the total memory requests\n calculated by adding the memory requests of all the containers (including the patroni container) you may set one or more of the following fields to `true`\n (depending on the resource's Pods you need this behaviour to be changed):\n \n* `SGCluster.spec.pods.resources.disableResourcesRequestsSplitFromTotal`\n* `SGShardedCluster.spec.coordinator.pods.resources.disableResourcesRequestsSplitFromTotal`\n* `SGShardedCluster.spec.shards.pods.resources.disableResourcesRequestsSplitFromTotal`\n* `SGShardedCluster.spec.shards.ovewrites.pods.resources.disableResourcesRequestsSplitFromTotal`\n* `SGDistributedLogs.spec.resources.disableResourcesRequestsSplitFromTotal`\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "containers" = mkOverride 1002 null;
        "cpu" = mkOverride 1002 null;
        "initContainers" = mkOverride 1002 null;
        "memory" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGPostgresConfig" = {

      options = {
        "apiVersion" = mkOption {
          description = "\nAPIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources\n";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "\nKind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds\n";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "";
          type = (submoduleOf "stackgres.io.v1.SGPostgresConfigSpec");
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGPostgresConfigStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGPostgresConfigSpec" = {

      options = {
        "postgresVersion" = mkOption {
          description = "The **major** Postgres version the configuration is for. Postgres major versions contain one number starting with version 10 (`10`, `11`, `12`, etc), and two numbers separated by a dot for previous versions (`9.6`, `9.5`, etc).\n\nNote that Postgres maintains full compatibility across minor versions, and hence a configuration for a given major version will work for any minor version of that same major version.\n\nCheck [StackGres component versions](https://stackgres.io/doc/latest/intro/versions) to see the Postgres versions supported by this version of StackGres.\n";
          type = types.str;
        };
        "postgresql.conf" = mkOption {
          description = "The `postgresql.conf` parameters the configuration contains, represented as an object where the keys are valid names for the `postgresql.conf` configuration file parameters of the given `postgresVersion`. You may check [postgresqlco.nf](https://postgresqlco.nf) as a reference on how to tune and find the valid parameters for a given major version.\n";
          type = (types.attrsOf types.str);
        };
      };

      config = { };

    };
    "stackgres.io.v1.SGPostgresConfigStatus" = {

      options = {
        "defaultParameters" = mkOption {
          description = "The `postgresql.conf` default parameters which are used if not set.\n";
          type = (types.attrsOf types.str);
        };
      };

      config = { };

    };
    "stackgres.io.v1.SGScript" = {

      options = {
        "apiVersion" = mkOption {
          description = "\nAPIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources\n";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "\nKind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds\n";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "";
          type = (submoduleOf "stackgres.io.v1.SGScriptSpec");
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGScriptStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGScriptSpec" = {

      options = {
        "continueOnError" = mkOption {
          description = "If `true`, when any script entry fail will not prevent subsequent script entries from being executed. `false` by default.\n";
          type = (types.nullOr types.bool);
        };
        "managedVersions" = mkOption {
          description = "If `true` the versions will be managed by the operator automatically. The user will still be able to update them if needed. `true` by default.\n";
          type = (types.nullOr types.bool);
        };
        "scripts" = mkOption {
          description = "A list of SQL scripts.\n";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "stackgres.io.v1.SGScriptSpecScripts" "name" [ "id" ]
            )
          );
          apply = attrsToList;
        };
      };

      config = {
        "continueOnError" = mkOverride 1002 null;
        "managedVersions" = mkOverride 1002 null;
        "scripts" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGScriptSpecScripts" = {

      options = {
        "database" = mkOption {
          description = "Database where the script is executed. Defaults to the `postgres` database, if not specified.\n";
          type = (types.nullOr types.str);
        };
        "id" = mkOption {
          description = "The id is immutable and must be unique across all the script entries. It is replaced by the operator and is used to identify the script for the whole life of the `SGScript` object.\n";
          type = (types.nullOr types.int);
        };
        "name" = mkOption {
          description = "Name of the script. Must be unique across this SGScript.\n";
          type = (types.nullOr types.str);
        };
        "retryOnError" = mkOption {
          description = "If not set or set to `false` the script entry will not be retried if it fails.\n\nWhen set to `true` the script execution will be retried with an exponential backoff of 5 minutes,\n  starting from 10 seconds and a standard deviation of 10 seconds.\n\nThis is `false` by default.\n";
          type = (types.nullOr types.bool);
        };
        "script" = mkOption {
          description = "Raw SQL script to execute. This field is mutually exclusive with `scriptFrom` field.\n";
          type = (types.nullOr types.str);
        };
        "scriptFrom" = mkOption {
          description = "Reference to either a Kubernetes [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) or a [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) that contains the SQL script to execute. This field is mutually exclusive with `script` field.\n\nFields `secretKeyRef` and `configMapKeyRef` are mutually exclusive, and one of them is required.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGScriptSpecScriptsScriptFrom"));
        };
        "storeStatusInDatabase" = mkOption {
          description = "When set to `true` the script entry execution will include storing the status of the execution of this\n  script entry in the table `managed_sql.status` that will be created in the specified `database`. This\n  will avoid an operation that fails partially to be unrecoverable requiring the intervention from the user\n  if user in conjunction with `retryOnError`.\n\nIf set to `true` then `wrapInTransaction` field must be set.\n\nThis is `false` by default.\n";
          type = (types.nullOr types.bool);
        };
        "user" = mkOption {
          description = "User that will execute the script. Defaults to the superuser username when not set (that by default is `postgres`) user.\n";
          type = (types.nullOr types.str);
        };
        "version" = mkOption {
          description = "Version of the script. It will allow to identify if this script entry has been changed.\n";
          type = (types.nullOr types.int);
        };
        "wrapInTransaction" = mkOption {
          description = "Wrap the script in a transaction using the specified transaction mode:\n\n* `read-committed`: The script will be wrapped in a transaction using [READ COMMITTED](https://www.postgresql.org/docs/current/transaction-iso.html#XACT-READ-COMMITTED) isolation level.\n* `repeatable-read`: The script will be wrapped in a transaction using [REPEATABLE READ](https://www.postgresql.org/docs/current/transaction-iso.html#XACT-REPEATABLE-READ) isolation level.\n* `serializable`: The script will be wrapped in a transaction using [SERIALIZABLE](https://www.postgresql.org/docs/current/transaction-iso.html#XACT-SERIALIZABLE) isolation level.\n\nIf not set the script entry will not be wrapped in a transaction\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "database" = mkOverride 1002 null;
        "id" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "retryOnError" = mkOverride 1002 null;
        "script" = mkOverride 1002 null;
        "scriptFrom" = mkOverride 1002 null;
        "storeStatusInDatabase" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
        "wrapInTransaction" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGScriptSpecScriptsScriptFrom" = {

      options = {
        "configMapKeyRef" = mkOption {
          description = "A [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) reference that contains the SQL script to execute. This field is mutually exclusive with `secretKeyRef` field.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGScriptSpecScriptsScriptFromConfigMapKeyRef"));
        };
        "secretKeyRef" = mkOption {
          description = "A Kubernetes [SecretKeySelector](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#secretkeyselector-v1-core) that contains the SQL script to execute. This field is mutually exclusive with `configMapKeyRef` field.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGScriptSpecScriptsScriptFromSecretKeyRef"));
        };
      };

      config = {
        "configMapKeyRef" = mkOverride 1002 null;
        "secretKeyRef" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGScriptSpecScriptsScriptFromConfigMapKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key name within the ConfigMap that contains the SQL script to execute.\n";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the ConfigMap that contains the SQL script to execute.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGScriptSpecScriptsScriptFromSecretKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from. Must be a valid secret key.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGScriptStatus" = {

      options = {
        "scripts" = mkOption {
          description = "A list of script entry statuses where a script entry under `.spec.scripts` is identified by the `id` field.\n";
          type = (types.nullOr (types.listOf (submoduleOf "stackgres.io.v1.SGScriptStatusScripts")));
        };
      };

      config = {
        "scripts" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGScriptStatusScripts" = {

      options = {
        "hash" = mkOption {
          description = "The hash of a ConfigMap or Secret referenced with the associated script entry.\n";
          type = (types.nullOr types.str);
        };
        "id" = mkOption {
          description = "The id that identifies a script entry.\n";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "hash" = mkOverride 1002 null;
        "id" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedBackup" = {

      options = {
        "apiVersion" = mkOption {
          description = "\nAPIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources\n";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "\nKind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds\n";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "";
          type = (submoduleOf "stackgres.io.v1.SGShardedBackupSpec");
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGShardedBackupStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedBackupSpec" = {

      options = {
        "managedLifecycle" = mkOption {
          description = "Indicate if this sharded backup is permanent and should not be removed by the automated\n retention policy. Default is `false`.\n";
          type = (types.nullOr types.bool);
        };
        "maxRetries" = mkOption {
          description = "The maximum number of retries the backup operation is allowed to do after a failure.\n\nA value of `0` (zero) means no retries are made. Defaults to: `3`.\n";
          type = (types.nullOr types.int);
        };
        "reconciliationTimeout" = mkOption {
          description = "Allow to set a timeout for the reconciliation process that take place after the backup.\n\nIf not set defaults to 300 (5 minutes). If set to 0 it will disable timeout.\n\nFailure of reconciliation will not make the backup fail and will be re-tried the next time a SGBackup\n or shecduled backup Job take place.\n";
          type = (types.nullOr types.int);
        };
        "sgShardedCluster" = mkOption {
          description = "The name of the `SGShardedCluster` from which this sharded backup is/will be taken.\n\nIf this is a copy of an existing completed sharded backup in a different namespace\n the value must be prefixed with the namespace of the source backup and a\n dot `.` (e.g. `<sharded cluster namespace>.<sharded cluster name>`) or have the same value\n if the source sharded backup is also a copy.\n";
          type = (types.nullOr types.str);
        };
        "timeout" = mkOption {
          description = "Allow to set a timeout for the backup creation.\n\nIf not set it will be disabled and the backup operation will continue until the backup completes or fail. If set to 0 is the same as not being set.\n\nMake sure to set a reasonable high value in order to allow for any unexpected delays during backup creation (network low bandwidth, disk low throughput and so forth).\n";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "managedLifecycle" = mkOverride 1002 null;
        "maxRetries" = mkOverride 1002 null;
        "reconciliationTimeout" = mkOverride 1002 null;
        "sgShardedCluster" = mkOverride 1002 null;
        "timeout" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedBackupStatus" = {

      options = {
        "backupInformation" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGShardedBackupStatusBackupInformation"));
        };
        "process" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGShardedBackupStatusProcess"));
        };
        "sgBackups" = mkOption {
          description = "The list of SGBackups that compose the SGShardedBackup used to restore the sharded cluster.\n";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "backupInformation" = mkOverride 1002 null;
        "process" = mkOverride 1002 null;
        "sgBackups" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedBackupStatusBackupInformation" = {

      options = {
        "postgresVersion" = mkOption {
          description = "Postgres version of the server where the sharded backup is taken from.\n";
          type = (types.nullOr types.str);
        };
        "size" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGShardedBackupStatusBackupInformationSize"));
        };
      };

      config = {
        "postgresVersion" = mkOverride 1002 null;
        "size" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedBackupStatusBackupInformationSize" = {

      options = {
        "compressed" = mkOption {
          description = "Size (in bytes) of the compressed sharded backup.\n";
          type = (types.nullOr types.int);
        };
        "uncompressed" = mkOption {
          description = "Size (in bytes) of the uncompressed sharded backup.\n";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "compressed" = mkOverride 1002 null;
        "uncompressed" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedBackupStatusProcess" = {

      options = {
        "failure" = mkOption {
          description = "If the status is `failed` this field will contain a message indicating the failure reason.\n";
          type = (types.nullOr types.str);
        };
        "jobPod" = mkOption {
          description = "Name of the pod assigned to the sharded backup. StackGres utilizes internally a locking mechanism based on the pod name of the job that creates the sharded backup.\n";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "Status of the sharded backup.\n";
          type = (types.nullOr types.str);
        };
        "timing" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGShardedBackupStatusProcessTiming"));
        };
      };

      config = {
        "failure" = mkOverride 1002 null;
        "jobPod" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "timing" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedBackupStatusProcessTiming" = {

      options = {
        "end" = mkOption {
          description = "End time of sharded backup.\n";
          type = (types.nullOr types.str);
        };
        "start" = mkOption {
          description = "Start time of sharded backup.\n";
          type = (types.nullOr types.str);
        };
        "stored" = mkOption {
          description = "Time at which the sharded backup is safely stored in the object storage.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "end" = mkOverride 1002 null;
        "start" = mkOverride 1002 null;
        "stored" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedDbOps" = {

      options = {
        "apiVersion" = mkOption {
          description = "\nAPIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources\n";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "\nKind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds\n";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "";
          type = (submoduleOf "stackgres.io.v1.SGShardedDbOpsSpec");
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGShardedDbOpsStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedDbOpsSpec" = {

      options = {
        "maxRetries" = mkOption {
          description = "The maximum number of retries the operation is allowed to do after a failure.\n\nA value of `0` (zero) means no retries are made. Defaults to: `0`.\n";
          type = (types.nullOr types.int);
        };
        "op" = mkOption {
          description = "The kind of operation that will be performed on the SGCluster. Available operations are:\n\n* `resharding`: perform a resharding of the cluster.\n* `restart`: perform a restart of the cluster.\n* `securityUpgrade`: perform a security upgrade of the cluster.\n";
          type = types.str;
        };
        "resharding" = mkOption {
          description = "Configuration for resharding. Resharding a sharded cluster is the operation that moves the data among shards in order to try to\n balance the disk space used in each shard. See also https://docs.citusdata.com/en/stable/develop/api_udf.html#citus-rebalance-start\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecResharding"));
        };
        "restart" = mkOption {
          description = "Configuration of restart\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecRestart"));
        };
        "runAt" = mkOption {
          description = "An ISO 8601 date, that holds UTC scheduled date of the operation execution.\n\nIf not specified or if the date it's in the past, it will be interpreted ASAP.\n";
          type = (types.nullOr types.str);
        };
        "scheduling" = mkOption {
          description = "Pod custom node scheduling and affinity configuration";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecScheduling"));
        };
        "securityUpgrade" = mkOption {
          description = "Configuration of security upgrade\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSecurityUpgrade"));
        };
        "sgShardedCluster" = mkOption {
          description = "The name of SGShardedCluster on which the operation will be performed.\n";
          type = types.str;
        };
        "timeout" = mkOption {
          description = "An ISO 8601 duration in the format `PnDTnHnMn.nS`, that specifies a timeout after which the operation execution will be canceled.\n\nIf the operation can not be performed due to timeout expiration, the condition `Failed` will have a status of `True` and the reason will be `OperationTimedOut`.\n\nIf not specified the operation will never fail for timeout expiration.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "maxRetries" = mkOverride 1002 null;
        "resharding" = mkOverride 1002 null;
        "restart" = mkOverride 1002 null;
        "runAt" = mkOverride 1002 null;
        "scheduling" = mkOverride 1002 null;
        "securityUpgrade" = mkOverride 1002 null;
        "timeout" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedDbOpsSpecResharding" = {

      options = {
        "citus" = mkOption {
          description = "Citus specific resharding parameters\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecReshardingCitus"));
        };
      };

      config = {
        "citus" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedDbOpsSpecReshardingCitus" = {

      options = {
        "drainOnly" = mkOption {
          description = "A float number between 0.0 and 1.0 which indicates the maximum difference ratio of node utilization from average utilization.\nSee also https://docs.citusdata.com/en/stable/develop/api_udf.html#citus-rebalance-start\n";
          type = (types.nullOr types.bool);
        };
        "rebalanceStrategy" = mkOption {
          description = "The name of a strategy in Rebalancer strategy table. Will pick a default one if not specified\nSee also https://docs.citusdata.com/en/stable/develop/api_udf.html#citus-rebalance-start\n";
          type = (types.nullOr types.str);
        };
        "threshold" = mkOption {
          description = "A float number between 0.0 and 1.0 which indicates the maximum difference ratio of node utilization from average utilization.\nSee also https://docs.citusdata.com/en/stable/develop/api_udf.html#citus-rebalance-start\n";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "drainOnly" = mkOverride 1002 null;
        "rebalanceStrategy" = mkOverride 1002 null;
        "threshold" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedDbOpsSpecRestart" = {

      options = {
        "method" = mkOption {
          description = "The method used to perform the restart operation. Available methods are:\n\n* `InPlace`: the in-place method does not require more resources than those that are available.\n  In case only an instance of the StackGres cluster for the coordinator or any shard is present\n  this mean the service disruption will last longer so we encourage use the reduced impact restart\n   and especially for a production environment.\n* `ReducedImpact`: this procedure is the same as the in-place method but require additional\n  resources in order to spawn a new updated replica that will be removed when the procedure completes.\n";
          type = (types.nullOr types.str);
        };
        "onlyPendingRestart" = mkOption {
          description = "By default all Pods are restarted. Setting this option to `true` allow to restart only those Pods which\n  are in pending restart state as detected by the operation. Defaults to: `false`.\n";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "method" = mkOverride 1002 null;
        "onlyPendingRestart" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedDbOpsSpecScheduling" = {

      options = {
        "nodeAffinity" = mkOption {
          description = "Node affinity is a group of node affinity scheduling rules.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#nodeaffinity-v1-core";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingNodeAffinity"));
        };
        "nodeSelector" = mkOption {
          description = "NodeSelector is a selector which must be true for the pod to fit on a node. Selector which must match a node's labels for the pod to be scheduled on that node. More info: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/\n";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "podAffinity" = mkOption {
          description = "Pod affinity is a group of inter pod affinity scheduling rules.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#podaffinity-v1-core";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinity"));
        };
        "podAntiAffinity" = mkOption {
          description = "Pod anti affinity is a group of inter pod anti affinity scheduling rules.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#podantiaffinity-v1-core";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinity"));
        };
        "priorityClassName" = mkOption {
          description = "If specified, indicates the pod's priority. \"system-node-critical\" and \"system-cluster-critical\" are two special keywords which indicate the highest priorities with the former being the highest priority. Any other name must be defined by creating a PriorityClass object with that name. If not specified, the pod priority will be default or zero if there is no default.";
          type = (types.nullOr types.str);
        };
        "tolerations" = mkOption {
          description = "If specified, the pod's tolerations.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#toleration-v1-core";
          type = (
            types.nullOr (types.listOf (submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingTolerations"))
          );
        };
      };

      config = {
        "nodeAffinity" = mkOverride 1002 null;
        "nodeSelector" = mkOverride 1002 null;
        "podAffinity" = mkOverride 1002 null;
        "podAntiAffinity" = mkOverride 1002 null;
        "priorityClassName" = mkOverride 1002 null;
        "tolerations" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingNodeAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy the affinity expressions specified by this field, but it may choose a node that violates one or more of the expressions. The node that is most preferred is the one with the greatest sum of weights, i.e. for each node that meets all of the scheduling requirements (resource request, requiredDuringScheduling affinity expressions, etc.), compute a sum by iterating through the elements of this field and adding \"weight\" to the sum if the node matches the corresponding matchExpressions; the node(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "A node selector represents the union of the results of one or more label queries over a set of nodes; that is, it represents the OR of the selectors represented by the node selector terms.";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution"
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "preference" = mkOption {
            description = "A null or empty node selector term matches no objects. The requirements of them are ANDed. The TopologySelectorTerm type implements a subset of the NodeSelectorTerm.";
            type = (
              submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference"
            );
          };
          "weight" = mkOption {
            description = "Weight associated with matching the corresponding nodeSelectorTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields"
                )
              )
            );
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchFields" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "nodeSelectorTerms" = mkOption {
            description = "Required. A list of node selector terms. The terms are ORed.";
            type = (
              types.listOf (
                submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms"
              )
            );
          };
        };

        config = { };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields"
                )
              )
            );
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchFields" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy the affinity expressions specified by this field, but it may choose a node that violates one or more of the expressions. The node that is most preferred is the one with the greatest sum of weights, i.e. for each node that meets all of the scheduling requirements (resource request, requiredDuringScheduling affinity expressions, etc.), compute a sum by iterating through the elements of this field and adding \"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the node(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at scheduling time, the pod will not be scheduled onto the node. If the affinity requirements specified by this field cease to be met at some point during pod execution (e.g. due to a pod label update), the system may or may not try to eventually evict the pod from its node. When there are multiple elements, the lists of nodes corresponding to each podAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Defines a set of pods (namely those matching the labelSelector relative to the given namespace(s)) that this pod should be co-located (affinity) or not co-located (anti-affinity) with, where co-located is defined as running on a node whose value of the label with key <topologyKey> matches that of any node on which a pod of the set of pods is running";
            type = (
              submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both matchLabelKeys and labelSelector. Also, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both mismatchLabelKeys and labelSelector. Also, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both matchLabelKeys and labelSelector. Also, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both mismatchLabelKeys and labelSelector. Also, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy the anti-affinity expressions specified by this field, but it may choose a node that violates one or more of the expressions. The node that is most preferred is the one with the greatest sum of weights, i.e. for each node that meets all of the scheduling requirements (resource request, requiredDuringScheduling anti-affinity expressions, etc.), compute a sum by iterating through the elements of this field and adding \"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the node(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the anti-affinity requirements specified by this field are not met at scheduling time, the pod will not be scheduled onto the node. If the anti-affinity requirements specified by this field cease to be met at some point during pod execution (e.g. due to a pod label update), the system may or may not try to eventually evict the pod from its node. When there are multiple elements, the lists of nodes corresponding to each podAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Defines a set of pods (namely those matching the labelSelector relative to the given namespace(s)) that this pod should be co-located (affinity) or not co-located (anti-affinity) with, where co-located is defined as running on a node whose value of the label with key <topologyKey> matches that of any node on which a pod of the set of pods is running";
            type = (
              submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both matchLabelKeys and labelSelector. Also, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both mismatchLabelKeys and labelSelector. Also, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both matchLabelKeys and labelSelector. Also, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both mismatchLabelKeys and labelSelector. Also, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1.SGShardedDbOpsSpecSchedulingTolerations" = {

      options = {
        "effect" = mkOption {
          description = "Effect indicates the taint effect to match. Empty means match all taint effects. When specified, allowed values are NoSchedule, PreferNoSchedule and NoExecute.";
          type = (types.nullOr types.str);
        };
        "key" = mkOption {
          description = "Key is the taint key that the toleration applies to. Empty means match all taint keys. If the key is empty, operator must be Exists; this combination means to match all values and all keys.";
          type = (types.nullOr types.str);
        };
        "operator" = mkOption {
          description = "Operator represents a key's relationship to the value. Valid operators are Exists and Equal. Defaults to Equal. Exists is equivalent to wildcard for value, so that a pod can tolerate all taints of a particular category.";
          type = (types.nullOr types.str);
        };
        "tolerationSeconds" = mkOption {
          description = "TolerationSeconds represents the period of time the toleration (which must be of effect NoExecute, otherwise this field is ignored) tolerates the taint. By default, it is not set, which means tolerate the taint forever (do not evict). Zero and negative values will be treated as 0 (evict immediately) by the system.";
          type = (types.nullOr types.int);
        };
        "value" = mkOption {
          description = "Value is the taint value the toleration matches to. If the operator is Exists, the value should be empty, otherwise just a regular string.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "effect" = mkOverride 1002 null;
        "key" = mkOverride 1002 null;
        "operator" = mkOverride 1002 null;
        "tolerationSeconds" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedDbOpsSpecSecurityUpgrade" = {

      options = {
        "method" = mkOption {
          description = "The method used to perform the security upgrade operation. Available methods are:\n\n* `InPlace`: the in-place method does not require more resources than those that are available.\n  In case only an instance of the StackGres cluster is present this mean the service disruption will\n  last longer so we encourage use the reduced impact restart and especially for a production environment.\n* `ReducedImpact`: this procedure is the same as the in-place method but require additional\n  resources in order to spawn a new updated replica that will be removed when the procedure completes.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "method" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedDbOpsStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Possible conditions are:\n\n* Running: to indicate when the operation is actually running\n* Completed: to indicate when the operation has completed successfully\n* Failed: to indicate when the operation has failed\n";
          type = (types.nullOr (types.listOf (submoduleOf "stackgres.io.v1.SGShardedDbOpsStatusConditions")));
        };
        "opRetries" = mkOption {
          description = "The number of retries performed by the operation\n";
          type = (types.nullOr types.int);
        };
        "opStarted" = mkOption {
          description = "The ISO 8601 timestamp of when the operation started running\n";
          type = (types.nullOr types.str);
        };
        "restart" = mkOption {
          description = "The results of a restart\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGShardedDbOpsStatusRestart"));
        };
        "securityUpgrade" = mkOption {
          description = "The results of a security upgrade\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1.SGShardedDbOpsStatusSecurityUpgrade"));
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "opRetries" = mkOverride 1002 null;
        "opStarted" = mkOverride 1002 null;
        "restart" = mkOverride 1002 null;
        "securityUpgrade" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedDbOpsStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "Last time the condition transitioned from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "A human-readable message indicating details about the transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "The reason for the condition last transition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "Status of the condition, one of `True`, `False` or `Unknown`.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "Type of deployment condition.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedDbOpsStatusRestart" = {

      options = {
        "failure" = mkOption {
          description = "A failure message (when available)\n";
          type = (types.nullOr types.str);
        };
        "pendingToRestartSgClusters" = mkOption {
          description = "The SGClusters that are pending to be restarted\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "restartedSgClusters" = mkOption {
          description = "The SGClusters that have been restarted\n";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "failure" = mkOverride 1002 null;
        "pendingToRestartSgClusters" = mkOverride 1002 null;
        "restartedSgClusters" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1.SGShardedDbOpsStatusSecurityUpgrade" = {

      options = {
        "failure" = mkOption {
          description = "A failure message (when available)\n";
          type = (types.nullOr types.str);
        };
        "pendingToRestartSgClusters" = mkOption {
          description = "The SGClusters that are pending to be restarted\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "restartedSgClusters" = mkOption {
          description = "The SGClusters that have been restarted\n";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "failure" = mkOverride 1002 null;
        "pendingToRestartSgClusters" = mkOverride 1002 null;
        "restartedSgClusters" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStream" = {

      options = {
        "apiVersion" = mkOption {
          description = "\nAPIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources\n";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "\nKind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds\n";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "Specification of the desired behavior of a StackGres stream.\n\nA stream represent the process of performing a change data capture (CDC) operation on a data source that generates a stream of event containing information about the changes happening (or happened) to the database in real time (or from the beginning).\n\nThe stream allow to specify different types for the target of the CDC operation. See `SGStream.spec.target.type`.\n\nThe stream perform two distinct operation to generate data source changes for the target:\n\n* Snapshotting: allows to capture the content of the data source in a specific point in time and stream it as if they were changes, thus providing a stream of events as they were an aggregate from the beginning of the existence of the data source.\n* Streaming: allows to capture the changes that are happening in real time in the data source and stream them as changes continuously.\n\nThe CDC is performed using [Debezium Engine](https://debezium.io/documentation/reference/stable/development/engine.html). SGStream extends functionality of Debezium by providing a [custom signaling channel](https://debezium.io/documentation/reference/stable/configuration/signalling.html#debezium-custom-signaling-channel) that allow to send signals by simply adding annotation to the SGStream resources.\nTo send a signal simply create an annotation with the following formar:\n\n```\nmetadata:\n  annotations:\n    debezium-signal.stackgres.io/<signal type>: <signal data>\n```\n\nAlso, SGStream provide the following custom singals implementations:\n  \n  * `tombstone`: allow to stop completely Debezium streaming and the SGStream. This signal is useful to give an end to the streaming in a graceful way allowing for the removal of the logical slot created by Debezium.\n  * `command`: allow to execute any SQL command on the target database. Only available then the target type is `SGCluster`.\n";
          type = (submoduleOf "stackgres.io.v1alpha1.SGStreamSpec");
        };
        "status" = mkOption {
          description = "Status of a StackGres stream.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpec" = {

      options = {
        "debeziumEngineProperties" = mkOption {
          description = "See https://debezium.io/documentation/reference/stable/development/engine.html#engine-properties\n Each property is converted from myPropertyName to my.property.name\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecDebeziumEngineProperties"));
        };
        "maxRetries" = mkOption {
          description = "The maximum number of retries the streaming operation is allowed to do after a failure.\n\nA value of `0` (zero) means no retries are made. A value of `-1` means retries are unlimited. Defaults to: `-1`.\n";
          type = (types.nullOr types.int);
        };
        "pods" = mkOption {
          description = "The configuration for SGStream Pod";
          type = (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPods");
        };
        "source" = mkOption {
          description = "The data source of the stream to which change data capture will be applied. \n";
          type = (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecSource");
        };
        "target" = mkOption {
          description = "The target of this sream.\n";
          type = (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecTarget");
        };
        "useDebeziumAsyncEngine" = mkOption {
          description = "When `true` use Debezium asyncronous engine. See https://debezium.io/blog/2024/07/08/async-embedded-engine/";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "debeziumEngineProperties" = mkOverride 1002 null;
        "maxRetries" = mkOverride 1002 null;
        "useDebeziumAsyncEngine" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecDebeziumEngineProperties" = {

      options = {
        "errorsMaxRetries" = mkOption {
          description = "Default `-1`. The maximum number of retries on connection errors before failing (-1 = no limit, 0 = disabled, > 0 = num of retries).\n";
          type = (types.nullOr types.int);
        };
        "errorsRetryDelayInitialMs" = mkOption {
          description = "Default `300`. Initial delay (in ms) for retries when encountering connection errors. This value will be doubled upon every retry but won’t exceed errorsRetryDelayMaxMs.\n";
          type = (types.nullOr types.int);
        };
        "errorsRetryDelayMaxMs" = mkOption {
          description = "Default `10000`. Max delay (in ms) between retries when encountering conn\n";
          type = (types.nullOr types.int);
        };
        "offsetCommitPolicy" = mkOption {
          description = "Default `io.debezium.engine.spi.OffsetCommitPolicy.PeriodicCommitOffsetPolicy`. The name of the Java class of the commit policy. It defines when offsets commit has to be triggered based on the number of events processed and the time elapsed since the last commit. This class must implement the interface OffsetCommitPolicy. The default is a periodic commity policy based upon time intervals.\n";
          type = (types.nullOr types.str);
        };
        "offsetFlushIntervalMs" = mkOption {
          description = "Default `60000`. Interval at which to try committing offsets. The default is 1 minute.\n";
          type = (types.nullOr types.int);
        };
        "offsetFlushTimeoutMs" = mkOption {
          description = "Default `5000`. Maximum number of milliseconds to wait for records to flush and partition offset data to be committed to offset storage before cancelling the process and restoring the offset data to be committed in a future attempt. The default is 5 seconds.\n";
          type = (types.nullOr types.int);
        };
        "predicates" = mkOption {
          description = "Predicates can be applied to transformations to make the transformations optional.\n\nAn example of the configuration is:\n\n```\npredicates:\n  headerExists: # (1)\n   type: \"org.apache.kafka.connect.transforms.predicates.HasHeaderKey\" # (2)\n   name: \"header.name\" # (3)\ntransforms:\n  filter: # (4)\n    type: \"io.debezium.embedded.ExampleFilterTransform\" # (5)\n    predicate: \"headerExists\" # (6)\n    negate: \"true\" # (7)\n```\n\n1. One predicate is defined - headerExists\n2. Implementation of the headerExists predicate is org.apache.kafka.connect.transforms.predicates.HasHeaderKey\n3. The headerExists predicate has one configuration option - name\n4. One transformation is defined - filter\n5. Implementation of the filter transformation is io.debezium.embedded.ExampleFilterTransform\n6. The filter transformation requires the predicate headerExists\n7. The filter transformation expects the value of the predicate to be negated, making the predicate determine if the header does not exist\n";
          type = (types.nullOr (types.attrsOf types.attrs));
        };
        "recordProcessingOrder" = mkOption {
          description = "Default `ORDERED`. \n\nDetermines how the records should be produced.\n\n* `ORDERED`\n\n  Records are processed sequentially; that is, they are produced in the order in which they were obtained from the database.\n\n* `UNORDERED`\n\n  Records are processed non-sequentially; that is, they can be produced in an different order than in the source database.\n\nThe non-sequential processing of the `UNORDERED` option results in better throughput, because records are produced immediately after any SMT processing and message serialization is complete, without waiting for other records. This option doesn’t have any effect when the ChangeConsumer method is provided to the engine.\n";
          type = (types.nullOr types.str);
        };
        "recordProcessingShutdownTimeoutMs" = mkOption {
          description = "Default `1000`. Maximum time in milliseconds to wait for processing submitted records after a task shutdown is called.";
          type = (types.nullOr types.int);
        };
        "recordProcessingThreads" = mkOption {
          description = "The number of threads that are available to process change event records. If no value is specified (the default), the engine uses the Java [ThreadPoolExecutor](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/ThreadPoolExecutor.html) to dynamically adjust the number of threads, based on the current workload. Maximum number of threads is number of CPU cores on given machine. If a value is specified, the engine uses the Java [fixed thread pool](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/Executors.html) method to create a thread pool with the specified number of threads. To use all available cores on given machine, set the placeholder value, AVAILABLE_CORES.\n";
          type = (types.nullOr types.int);
        };
        "recordProcessingWithSerialConsumer" = mkOption {
          description = "Default `false`. Specifies whether the default ChangeConsumer should be created from the provided Consumer, resulting in serial Consumer processing. This option has no effect if you specified the ChangeConsumer interface when you used the API to create the engine.";
          type = (types.nullOr types.bool);
        };
        "taskManagementTimeoutMs" = mkOption {
          description = "Default `180000`. Time, in milliseconds, that the engine waits for a task’s lifecycle management operations (starting and stopping) to complete.";
          type = (types.nullOr types.int);
        };
        "transforms" = mkOption {
          description = "Before the messages are delivered to the handler it is possible to run them through a pipeline of Kafka Connect Simple Message Transforms (SMT). Each SMT can pass the message unchanged, modify it or filter it out. The chain is configured using property transforms. The property contains a list of logical names of the transformations to be applied (the specified keys). Properties transforms.<logical_name>.type then defines the name of the implementation class for each transformation and transforms.<logical_name>.* configuration options that are passed to the transformation.\n\nAn example of the configuration is:\n\n```\ntransforms: # (1)\n  router:\n    type: \"org.apache.kafka.connect.transforms.RegexRouter\" # (2)\n    regex: \"(.*)\" # (3)\n    replacement: \"trf$1\" # (3)\n  filter:\n    type: \"io.debezium.embedded.ExampleFilterTransform\" # (4)\n```\n\n1. Two transformations are defined - filter and router\n2. Implementation of the router transformation is org.apache.kafka.connect.transforms.RegexRouter\n3. The router transformation has two configurations options -regex and replacement\n4. Implementation of the filter transformation is io.debezium.embedded.ExampleFilterTransform\n";
          type = (types.nullOr (types.attrsOf types.attrs));
        };
      };

      config = {
        "errorsMaxRetries" = mkOverride 1002 null;
        "errorsRetryDelayInitialMs" = mkOverride 1002 null;
        "errorsRetryDelayMaxMs" = mkOverride 1002 null;
        "offsetCommitPolicy" = mkOverride 1002 null;
        "offsetFlushIntervalMs" = mkOverride 1002 null;
        "offsetFlushTimeoutMs" = mkOverride 1002 null;
        "predicates" = mkOverride 1002 null;
        "recordProcessingOrder" = mkOverride 1002 null;
        "recordProcessingShutdownTimeoutMs" = mkOverride 1002 null;
        "recordProcessingThreads" = mkOverride 1002 null;
        "recordProcessingWithSerialConsumer" = mkOverride 1002 null;
        "taskManagementTimeoutMs" = mkOverride 1002 null;
        "transforms" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecPods" = {

      options = {
        "persistentVolume" = mkOption {
          description = "Pod's persistent volume configuration.\n\n**Example:**\n\n```yaml\napiVersion: stackgres.io/v1\nkind: SGCluster\nmetadata:\n  name: stackgres\nspec:\n  pods:\n    persistentVolume:\n      size: '5Gi'\n      storageClass: default\n```\n";
          type = (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsPersistentVolume");
        };
        "resources" = mkOption {
          description = "The resources assigned to the stream container.\n\nSee https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsResources"));
        };
        "scheduling" = mkOption {
          description = "Pod custom scheduling, affinity and topology spread constratins configuration.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsScheduling"));
        };
      };

      config = {
        "resources" = mkOverride 1002 null;
        "scheduling" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecPodsPersistentVolume" = {

      options = {
        "size" = mkOption {
          description = "Size of the PersistentVolume for stream Pod. This size is specified either in Mebibytes, Gibibytes or Tebibytes (multiples of 2^20, 2^30 or 2^40, respectively).\n";
          type = types.str;
        };
        "storageClass" = mkOption {
          description = "Name of an existing StorageClass in the Kubernetes cluster, used to create the PersistentVolume for stream.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "storageClass" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecPodsResources" = {

      options = {
        "claims" = mkOption {
          description = "Claims lists the names of resources, defined in spec.resourceClaims, that are used by this container.\n\nThis is an alpha field and requires enabling the DynamicResourceAllocation feature gate.\n\nThis field is immutable. It can only be set for containers.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "stackgres.io.v1alpha1.SGStreamSpecPodsResourcesClaims" "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "limits" = mkOption {
          description = "Limits describes the maximum amount of compute resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "requests" = mkOption {
          description = "Requests describes the minimum amount of compute resources required. If Requests is omitted for a container, it defaults to Limits if that is explicitly specified, otherwise to an implementation-defined value. Requests cannot exceed Limits. More info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "claims" = mkOverride 1002 null;
        "limits" = mkOverride 1002 null;
        "requests" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecPodsResourcesClaims" = {

      options = {
        "name" = mkOption {
          description = "Name must match the name of one entry in pod.spec.resourceClaims of the Pod where this field is used. It makes that resource available inside a container.";
          type = types.str;
        };
        "request" = mkOption {
          description = "Request is the name chosen for a request in the referenced claim. If empty, everything from the claim is made available, otherwise only the result of this request.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "request" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecPodsScheduling" = {

      options = {
        "nodeAffinity" = mkOption {
          description = "Node affinity is a group of node affinity scheduling rules.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#nodeaffinity-v1-core";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingNodeAffinity"));
        };
        "nodeSelector" = mkOption {
          description = "NodeSelector is a selector which must be true for the pod to fit on a node. Selector which must match a node's labels for the pod to be scheduled on that node. More info: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/\n";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "podAffinity" = mkOption {
          description = "Pod affinity is a group of inter pod affinity scheduling rules.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#podaffinity-v1-core";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinity"));
        };
        "podAntiAffinity" = mkOption {
          description = "Pod anti affinity is a group of inter pod anti affinity scheduling rules.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#podantiaffinity-v1-core";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinity")
          );
        };
        "priorityClassName" = mkOption {
          description = "If specified, indicates the pod's priority. \"system-node-critical\" and \"system-cluster-critical\" are two special keywords which indicate the highest priorities with the former being the highest priority. Any other name must be defined by creating a PriorityClass object with that name. If not specified, the pod priority will be default or zero if there is no default.";
          type = (types.nullOr types.str);
        };
        "tolerations" = mkOption {
          description = "If specified, the pod's tolerations.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#toleration-v1-core";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingTolerations")
            )
          );
        };
        "topologySpreadConstraints" = mkOption {
          description = "TopologySpreadConstraints describes how a group of pods ought to spread across topology domains. Scheduler will schedule pods in a way which abides by the constraints. All topologySpreadConstraints are ANDed.\n\nSee https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#topologyspreadconstraint-v1-core";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingTopologySpreadConstraints"
              )
            )
          );
        };
      };

      config = {
        "nodeAffinity" = mkOverride 1002 null;
        "nodeSelector" = mkOverride 1002 null;
        "podAffinity" = mkOverride 1002 null;
        "podAntiAffinity" = mkOverride 1002 null;
        "priorityClassName" = mkOverride 1002 null;
        "tolerations" = mkOverride 1002 null;
        "topologySpreadConstraints" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingNodeAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy the affinity expressions specified by this field, but it may choose a node that violates one or more of the expressions. The node that is most preferred is the one with the greatest sum of weights, i.e. for each node that meets all of the scheduling requirements (resource request, requiredDuringScheduling affinity expressions, etc.), compute a sum by iterating through the elements of this field and adding \"weight\" to the sum if the node matches the corresponding matchExpressions; the node(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "A node selector represents the union of the results of one or more label queries over a set of nodes; that is, it represents the OR of the selectors represented by the node selector terms.";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution"
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "preference" = mkOption {
            description = "A null or empty node selector term matches no objects. The requirements of them are ANDed. The TopologySelectorTerm type implements a subset of the NodeSelectorTerm.";
            type = (
              submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference"
            );
          };
          "weight" = mkOption {
            description = "Weight associated with matching the corresponding nodeSelectorTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields"
                )
              )
            );
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchFields" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "nodeSelectorTerms" = mkOption {
            description = "Required. A list of node selector terms. The terms are ORed.";
            type = (
              types.listOf (
                submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms"
              )
            );
          };
        };

        config = { };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields"
                )
              )
            );
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchFields" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy the affinity expressions specified by this field, but it may choose a node that violates one or more of the expressions. The node that is most preferred is the one with the greatest sum of weights, i.e. for each node that meets all of the scheduling requirements (resource request, requiredDuringScheduling affinity expressions, etc.), compute a sum by iterating through the elements of this field and adding \"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the node(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at scheduling time, the pod will not be scheduled onto the node. If the affinity requirements specified by this field cease to be met at some point during pod execution (e.g. due to a pod label update), the system may or may not try to eventually evict the pod from its node. When there are multiple elements, the lists of nodes corresponding to each podAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Defines a set of pods (namely those matching the labelSelector relative to the given namespace(s)) that this pod should be co-located (affinity) or not co-located (anti-affinity) with, where co-located is defined as running on a node whose value of the label with key <topologyKey> matches that of any node on which a pod of the set of pods is running";
            type = (
              submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both matchLabelKeys and labelSelector. Also, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both mismatchLabelKeys and labelSelector. Also, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both matchLabelKeys and labelSelector. Also, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both mismatchLabelKeys and labelSelector. Also, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy the anti-affinity expressions specified by this field, but it may choose a node that violates one or more of the expressions. The node that is most preferred is the one with the greatest sum of weights, i.e. for each node that meets all of the scheduling requirements (resource request, requiredDuringScheduling anti-affinity expressions, etc.), compute a sum by iterating through the elements of this field and adding \"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the node(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the anti-affinity requirements specified by this field are not met at scheduling time, the pod will not be scheduled onto the node. If the anti-affinity requirements specified by this field cease to be met at some point during pod execution (e.g. due to a pod label update), the system may or may not try to eventually evict the pod from its node. When there are multiple elements, the lists of nodes corresponding to each podAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Defines a set of pods (namely those matching the labelSelector relative to the given namespace(s)) that this pod should be co-located (affinity) or not co-located (anti-affinity) with, where co-located is defined as running on a node whose value of the label with key <topologyKey> matches that of any node on which a pod of the set of pods is running";
            type = (
              submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both matchLabelKeys and labelSelector. Also, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both mismatchLabelKeys and labelSelector. Also, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both matchLabelKeys and labelSelector. Also, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will be taken into consideration. The keys are used to lookup values from the incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)` to select the group of existing pods which pods will be taken into consideration for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming pod labels will be ignored. The default value is empty. The same key is forbidden to exist in both mismatchLabelKeys and labelSelector. Also, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
            type = (
              types.nullOr (
                submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingTolerations" = {

      options = {
        "effect" = mkOption {
          description = "Effect indicates the taint effect to match. Empty means match all taint effects. When specified, allowed values are NoSchedule, PreferNoSchedule and NoExecute.";
          type = (types.nullOr types.str);
        };
        "key" = mkOption {
          description = "Key is the taint key that the toleration applies to. Empty means match all taint keys. If the key is empty, operator must be Exists; this combination means to match all values and all keys.";
          type = (types.nullOr types.str);
        };
        "operator" = mkOption {
          description = "Operator represents a key's relationship to the value. Valid operators are Exists and Equal. Defaults to Equal. Exists is equivalent to wildcard for value, so that a pod can tolerate all taints of a particular category.";
          type = (types.nullOr types.str);
        };
        "tolerationSeconds" = mkOption {
          description = "TolerationSeconds represents the period of time the toleration (which must be of effect NoExecute, otherwise this field is ignored) tolerates the taint. By default, it is not set, which means tolerate the taint forever (do not evict). Zero and negative values will be treated as 0 (evict immediately) by the system.";
          type = (types.nullOr types.int);
        };
        "value" = mkOption {
          description = "Value is the taint value the toleration matches to. If the operator is Exists, the value should be empty, otherwise just a regular string.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "effect" = mkOverride 1002 null;
        "key" = mkOverride 1002 null;
        "operator" = mkOverride 1002 null;
        "tolerationSeconds" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingTopologySpreadConstraints" = {

      options = {
        "labelSelector" = mkOption {
          description = "A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingTopologySpreadConstraintsLabelSelector"
            )
          );
        };
        "matchLabelKeys" = mkOption {
          description = "MatchLabelKeys is a set of pod label keys to select the pods over which spreading will be calculated. The keys are used to lookup values from the incoming pod labels, those key-value labels are ANDed with labelSelector to select the group of existing pods over which spreading will be calculated for the incoming pod. The same key is forbidden to exist in both MatchLabelKeys and LabelSelector. MatchLabelKeys cannot be set when LabelSelector isn't set. Keys that don't exist in the incoming pod labels will be ignored. A null or empty list means only match against labelSelector.\n\nThis is a beta field and requires the MatchLabelKeysInPodTopologySpread feature gate to be enabled (enabled by default).";
          type = (types.nullOr (types.listOf types.str));
        };
        "maxSkew" = mkOption {
          description = "MaxSkew describes the degree to which pods may be unevenly distributed. When `whenUnsatisfiable=DoNotSchedule`, it is the maximum permitted difference between the number of matching pods in the target topology and the global minimum. The global minimum is the minimum number of matching pods in an eligible domain or zero if the number of eligible domains is less than MinDomains. For example, in a 3-zone cluster, MaxSkew is set to 1, and pods with the same labelSelector spread as 2/2/1: In this case, the global minimum is 1. | zone1 | zone2 | zone3 | |  P P  |  P P  |   P   | - if MaxSkew is 1, incoming pod can only be scheduled to zone3 to become 2/2/2; scheduling it onto zone1(zone2) would make the ActualSkew(3-1) on zone1(zone2) violate MaxSkew(1). - if MaxSkew is 2, incoming pod can be scheduled onto any zone. When `whenUnsatisfiable=ScheduleAnyway`, it is used to give higher precedence to topologies that satisfy it. It's a required field. Default value is 1 and 0 is not allowed.";
          type = types.int;
        };
        "minDomains" = mkOption {
          description = "MinDomains indicates a minimum number of eligible domains. When the number of eligible domains with matching topology keys is less than minDomains, Pod Topology Spread treats \"global minimum\" as 0, and then the calculation of Skew is performed. And when the number of eligible domains with matching topology keys equals or greater than minDomains, this value has no effect on scheduling. As a result, when the number of eligible domains is less than minDomains, scheduler won't schedule more than maxSkew Pods to those domains. If value is nil, the constraint behaves as if MinDomains is equal to 1. Valid values are integers greater than 0. When value is not nil, WhenUnsatisfiable must be DoNotSchedule.\n\nFor example, in a 3-zone cluster, MaxSkew is set to 2, MinDomains is set to 5 and pods with the same labelSelector spread as 2/2/2: | zone1 | zone2 | zone3 | |  P P  |  P P  |  P P  | The number of domains is less than 5(MinDomains), so \"global minimum\" is treated as 0. In this situation, new pod with the same labelSelector cannot be scheduled, because computed skew will be 3(3 - 0) if new Pod is scheduled to any of the three zones, it will violate MaxSkew.";
          type = (types.nullOr types.int);
        };
        "nodeAffinityPolicy" = mkOption {
          description = "NodeAffinityPolicy indicates how we will treat Pod's nodeAffinity/nodeSelector when calculating pod topology spread skew. Options are: - Honor: only nodes matching nodeAffinity/nodeSelector are included in the calculations. - Ignore: nodeAffinity/nodeSelector are ignored. All nodes are included in the calculations.\n\nIf this value is nil, the behavior is equivalent to the Honor policy.";
          type = (types.nullOr types.str);
        };
        "nodeTaintsPolicy" = mkOption {
          description = "NodeTaintsPolicy indicates how we will treat node taints when calculating pod topology spread skew. Options are: - Honor: nodes without taints, along with tainted nodes for which the incoming pod has a toleration, are included. - Ignore: node taints are ignored. All nodes are included.\n\nIf this value is nil, the behavior is equivalent to the Ignore policy.";
          type = (types.nullOr types.str);
        };
        "topologyKey" = mkOption {
          description = "TopologyKey is the key of node labels. Nodes that have a label with this key and identical values are considered to be in the same topology. We consider each <key, value> as a \"bucket\", and try to put balanced number of pods into each bucket. We define a domain as a particular instance of a topology. Also, we define an eligible domain as a domain whose nodes meet the requirements of nodeAffinityPolicy and nodeTaintsPolicy. e.g. If TopologyKey is \"kubernetes.io/hostname\", each Node is a domain of that topology. And, if TopologyKey is \"topology.kubernetes.io/zone\", each zone is a domain of that topology. It's a required field.";
          type = types.str;
        };
        "whenUnsatisfiable" = mkOption {
          description = "WhenUnsatisfiable indicates how to deal with a pod if it doesn't satisfy the spread constraint. - DoNotSchedule (default) tells the scheduler not to schedule it. - ScheduleAnyway tells the scheduler to schedule the pod in any location,\n  but giving higher precedence to topologies that would help reduce the\n  skew.\nA constraint is considered \"Unsatisfiable\" for an incoming pod if and only if every possible node assignment for that pod would violate \"MaxSkew\" on some topology. For example, in a 3-zone cluster, MaxSkew is set to 1, and pods with the same labelSelector spread as 3/1/1: | zone1 | zone2 | zone3 | | P P P |   P   |   P   | If WhenUnsatisfiable is set to DoNotSchedule, incoming pod can only be scheduled to zone2(zone3) to become 3/2/1(3/1/2) as ActualSkew(2-1) on zone2(zone3) satisfies MaxSkew(1). In other words, the cluster can still be imbalanced, but scheduler won't make it *more* imbalanced. It's a required field.";
          type = types.str;
        };
      };

      config = {
        "labelSelector" = mkOverride 1002 null;
        "matchLabelKeys" = mkOverride 1002 null;
        "minDomains" = mkOverride 1002 null;
        "nodeAffinityPolicy" = mkOverride 1002 null;
        "nodeTaintsPolicy" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingTopologySpreadConstraintsLabelSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingTopologySpreadConstraintsLabelSelectorMatchExpressions"
              )
            )
          );
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecPodsSchedulingTopologySpreadConstraintsLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "stackgres.io.v1alpha1.SGStreamSpecSource" = {

      options = {
        "postgres" = mkOption {
          description = "The configuration of the data source required when type is `Postgres`.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecSourcePostgres"));
        };
        "sgCluster" = mkOption {
          description = "The configuration of the data source required when type is `SGCluster`.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecSourceSgCluster"));
        };
        "type" = mkOption {
          description = "The type of data source. Available data source types are:\n\n* `SGCluster`: an SGCluster in the same namespace\n* `Postgres`: any Postgres instance\n";
          type = types.str;
        };
      };

      config = {
        "postgres" = mkOverride 1002 null;
        "sgCluster" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecSourcePostgres" = {

      options = {
        "database" = mkOption {
          description = "The target database name to which the CDC process will connect to.\n\nIf not specified the default postgres database will be targeted.\n";
          type = (types.nullOr types.str);
        };
        "debeziumProperties" = mkOption {
          description = "Specific property of the debezium Postgres connector.\n\nSee https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-connector-properties\n\nEach property is converted from myPropertyName to my.property.name\n";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecSourcePostgresDebeziumProperties")
          );
        };
        "excludes" = mkOption {
          description = "A list of regular expressions that allow to match one or more `<schema>.<table>.<column>` entries to be filtered out before sending to the target.\n\nThis property is mutually exclusive with `includes`.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "host" = mkOption {
          description = "The hostname of the Postgres instance.\n";
          type = types.str;
        };
        "includes" = mkOption {
          description = "A list of regular expressions that allow to match one or more `<schema>.<table>.<column>` entries to be filtered before sending to the target.\n\nThis property is mutually exclusive with `excludes`.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "password" = mkOption {
          description = "The password used by the CDC process to connect to the database.\n\nIf not specified the default superuser password will be used.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecSourcePostgresPassword"));
        };
        "port" = mkOption {
          description = "The port of the Postgres instance. When not specified port 5432 will be used.\n";
          type = (types.nullOr types.int);
        };
        "username" = mkOption {
          description = "The username used by the CDC process to connect to the database.\n\nIf not specified the default superuser username (by default postgres) will be used.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecSourcePostgresUsername"));
        };
      };

      config = {
        "database" = mkOverride 1002 null;
        "debeziumProperties" = mkOverride 1002 null;
        "excludes" = mkOverride 1002 null;
        "includes" = mkOverride 1002 null;
        "password" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "username" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecSourcePostgresDebeziumProperties" = {

      options = {
        "binaryHandlingMode" = mkOption {
          description = "Default `bytes`. Specifies how binary (bytea) columns should be represented in change events:\n\n* `bytes` represents binary data as byte array.\n* `base64` represents binary data as base64-encoded strings.\n* `base64-url-safe` represents binary data as base64-url-safe-encoded strings.\n* `hex` represents binary data as hex-encoded (base16) strings.\n";
          type = (types.nullOr types.str);
        };
        "columnMaskHash" = mkOption {
          description = "An optional section, that allow to specify, for an hash algorithm and a salt, a list of regular expressions that match the fully-qualified names of character-based columns. Fully-qualified names for columns are of the form <schemaName>.<tableName>.<columnName>.\n To match the name of a column Debezium applies the regular expression that you specify as an anchored regular expression. That is, the specified expression is matched against the entire name string of the column; the expression does not match substrings that might be present in a column name. In the resulting change event record, the values for the specified columns are replaced with pseudonyms.\n A pseudonym consists of the hashed value that results from applying the specified hashAlgorithm and salt. Based on the hash function that is used, referential integrity is maintained, while column values are replaced with pseudonyms. Supported hash functions are described in the [MessageDigest section](https://docs.oracle.com/javase/7/docs/technotes/guides/security/StandardNames.html#MessageDigest) of the Java Cryptography Architecture Standard Algorithm Name Documentation.\n In the following example, CzQMA0cB5K is a randomly selected salt.\n columnMaskHash.SHA-256.CzQMA0cB5K=[inventory.orders.customerName,inventory.shipment.customerName]\n If necessary, the pseudonym is automatically shortened to the length of the column. The connector configuration can include multiple properties that specify different hash algorithms and salts.\n Depending on the hash algorithm used, the salt selected, and the actual data set, the resulting data set might not be completely masked.\n";
          type = (types.nullOr (types.attrsOf types.attrs));
        };
        "columnMaskHashV2" = mkOption {
          description = "Similar to also columnMaskHash but using hashing strategy version 2.\n Hashing strategy version 2 should be used to ensure fidelity if the value is being hashed in different places or systems.\n";
          type = (types.nullOr (types.attrsOf types.attrs));
        };
        "columnMaskWithLengthChars" = mkOption {
          description = "An optional, list of regular expressions that match the fully-qualified names of character-based columns. Set this property if you want the connector to mask the values for a set of columns, for example, if they contain sensitive data. Set length to a positive integer to replace data in the specified columns with the number of asterisk (*) characters specified by the length in the property name. Set length to 0 (zero) to replace data in the specified columns with an empty string.\n The fully-qualified name of a column observes the following format: schemaName.tableName.columnName.\n To match the name of a column, Debezium applies the regular expression that you specify as an anchored regular expression. That is, the specified expression is matched against the entire name string of the column; the expression does not match substrings that might be present in a column name.\n You can specify multiple properties with different lengths in a single configuration.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "columnPropagateSourceType" = mkOption {
          description = "Default `[.*]`. An optional, list of regular expressions that match the fully-qualified names of columns for which you want the connector to emit extra parameters that represent column metadata. When this property is set, the connector adds the following fields to the schema of event records:\n\n* `__debezium.source.column.type`\n* `__debezium.source.column.length`\n* `__debezium.source.column.scale`\n\nThese parameters propagate a column’s original type name and length (for variable-width types), respectively.\n Enabling the connector to emit this extra data can assist in properly sizing specific numeric or character-based columns in sink databases.\n The fully-qualified name of a column observes one of the following formats: databaseName.tableName.columnName, or databaseName.schemaName.tableName.columnName.\n To match the name of a column, Debezium applies the regular expression that you specify as an anchored regular expression. That is, the specified expression is matched against the entire name string of the column; the expression does not match substrings that might be present in a column name.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "columnTruncateToLengthChars" = mkOption {
          description = "An optional, list of regular expressions that match the fully-qualified names of character-based columns. Set this property if you want to truncate the data in a set of columns when it exceeds the number of characters specified by the length in the property name. Set length to a positive integer value, for example, column.truncate.to.20.chars.\n The fully-qualified name of a column observes the following format: <schemaName>.<tableName>.<columnName>.\n To match the name of a column, Debezium applies the regular expression that you specify as an anchored regular expression. That is, the specified expression is matched against the entire name string of the column; the expression does not match substrings that might be present in a column name.\n You can specify multiple properties with different lengths in a single configuration.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "converters" = mkOption {
          description = "Enumerates a comma-separated list of the symbolic names of the [custom converter](https://debezium.io/documentation/reference/stable/development/converters.html#custom-converters) instances that the connector can use. For example,\n\n```\nisbn:\n  type: io.debezium.test.IsbnConverter\n  schemaName: io.debezium.postgresql.type.Isbn\n```\n\nYou must set the converters property to enable the connector to use a custom converter.\n For each converter that you configure for a connector, you must also add a .type property, which specifies the fully-qualified name of the class that implements the converter interface.\nIf you want to further control the behavior of a configured converter, you can add one or more configuration parameters to pass values to the converter. To associate any additional configuration parameter with a converter, prefix the parameter names with the symbolic name of the converter.\n Each property is converted from myPropertyName to my.property.name\n";
          type = (types.nullOr (types.attrsOf types.attrs));
        };
        "customMetricTags" = mkOption {
          description = "The custom metric tags will accept key-value pairs to customize the MBean object name which should be appended the end of regular name, each key would represent a tag for the MBean object name, and the corresponding value would be the value of that tag the key is. For example:\n\n```\ncustomMetricTags:\n  k1: v1\n  k2: v2\n```\n";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "databaseInitialStatements" = mkOption {
          description = "A list of SQL statements that the connector executes when it establishes a JDBC connection to the database.\n The connector may establish JDBC connections at its own discretion. Consequently, this property is useful for configuration of session parameters only, and not for executing DML statements.\n The connector does not execute these statements when it creates a connection for reading the transaction log.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "databaseQueryTimeoutMs" = mkOption {
          description = "Default `0`. Specifies the time, in milliseconds, that the connector waits for a query to complete. Set the value to 0 (zero) to remove the timeout limit.\n";
          type = (types.nullOr types.int);
        };
        "datatypePropagateSourceType" = mkOption {
          description = "Default `[.*]`. An optional, list of regular expressions that specify the fully-qualified names of data types that are defined for columns in a database. When this property is set, for columns with matching data types, the connector emits event records that include the following extra fields in their schema:\n\n* `__debezium.source.column.type`\n* `__debezium.source.column.length`\n* `__debezium.source.column.scale`\n\nThese parameters propagate a column’s original type name and length (for variable-width types), respectively.\n Enabling the connector to emit this extra data can assist in properly sizing specific numeric or character-based columns in sink databases.\n The fully-qualified name of a column observes one of the following formats: databaseName.tableName.typeName, or databaseName.schemaName.tableName.typeName.\n To match the name of a data type, Debezium applies the regular expression that you specify as an anchored regular expression. That is, the specified expression is matched against the entire name string of the data type; the expression does not match substrings that might be present in a type name.\n For the list of PostgreSQL-specific data type names, see the [PostgreSQL data type mappings](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-data-types).\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "decimalHandlingMode" = mkOption {
          description = "Default `precise`. Specifies how the connector should handle values for DECIMAL and NUMERIC columns:\n\n* `precise`: represents values by using java.math.BigDecimal to represent values in binary form in change events.\n* `double`: represents values by using double values, which might result in a loss of precision but which is easier to use.\n* `string`: encodes values as formatted strings, which are easy to consume but semantic information about the real type is lost. For more information, see [Decimal types](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-decimal-types).\n";
          type = (types.nullOr types.str);
        };
        "errorsMaxRetries" = mkOption {
          description = "Default `-1`. Specifies how the connector responds after an operation that results in a retriable error, such as a connection error.\n\nSet one of the following options:\n\n* `-1`: No limit. The connector always restarts automatically, and retries the operation, regardless of the number of previous failures.\n* `0`: Disabled. The connector fails immediately, and never retries the operation. User intervention is required to restart the connector.\n* `> 0`: The connector restarts automatically until it reaches the specified maximum number of retries. After the next failure, the connector stops, and user intervention is required to restart it.\n";
          type = (types.nullOr types.int);
        };
        "eventProcessingFailureHandlingMode" = mkOption {
          description = "Default `fail`. Specifies how the connector should react to exceptions during processing of events:\n\n* `fail`: propagates the exception, indicates the offset of the problematic event, and causes the connector to stop.\n* `warn`: logs the offset of the problematic event, skips that event, and continues processing.\n* `skip`: skips the problematic event and continues processing.\n";
          type = (types.nullOr types.str);
        };
        "fieldNameAdjustmentMode" = mkOption {
          description = "Default `none`. Specifies how field names should be adjusted for compatibility with the message converter used by the connector. Possible settings:\n\n* `none` does not apply any adjustment.\n* `avro` replaces the characters that cannot be used in the Avro type name with underscore.\n* `avro_unicode` replaces the underscore or characters that cannot be used in the Avro type name with corresponding unicode like _uxxxx. Note: _ is an escape sequence like backslash in Java\n\nFor more information, see [Avro naming](https://debezium.io/documentation/reference/stable/configuration/avro.html#avro-naming).\n";
          type = (types.nullOr types.str);
        };
        "flushLsnSource" = mkOption {
          description = "Default `true`. Determines whether the connector should commit the LSN of the processed records in the source postgres database so that the WAL logs can be deleted. Specify false if you don’t want the connector to do this. Please note that if set to false LSN will not be acknowledged by Debezium and as a result WAL logs will not be cleared which might result in disk space issues. User is expected to handle the acknowledgement of LSN outside Debezium.\n";
          type = (types.nullOr types.bool);
        };
        "heartbeatActionQuery" = mkOption {
          description = "Specifies a query that the connector executes on the source database when the connector sends a heartbeat message.\n This is useful for resolving the situation described in [WAL disk space consumption](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-wal-disk-space), where capturing changes from a low-traffic database on the same host as a high-traffic database prevents Debezium from processing WAL records and thus acknowledging WAL positions with the database. To address this situation, create a heartbeat table in the low-traffic database, and set this property to a statement that inserts records into that table, for example:\n\n ```\n INSERT INTO test_heartbeat_table (text) VALUES ('test_heartbeat')\n ```\n \n This allows the connector to receive changes from the low-traffic database and acknowledge their LSNs, which prevents unbounded WAL growth on the database host.\n";
          type = (types.nullOr types.str);
        };
        "heartbeatIntervalMs" = mkOption {
          description = "Default `0`. Controls how frequently the connector sends heartbeat messages to a target topic. The default behavior is that the connector does not send heartbeat messages.\n Heartbeat messages are useful for monitoring whether the connector is receiving change events from the database. Heartbeat messages might help decrease the number of change events that need to be re-sent when a connector restarts. To send heartbeat messages, set this property to a positive integer, which indicates the number of milliseconds between heartbeat messages.\n Heartbeat messages are needed when there are many updates in a database that is being tracked but only a tiny number of updates are related to the table(s) and schema(s) for which the connector is capturing changes. In this situation, the connector reads from the database transaction log as usual but rarely emits change records to target. This means that no offset updates are committed to target and the connector does not have an opportunity to send the latest retrieved LSN to the database. The database retains WAL files that contain events that have already been processed by the connector. Sending heartbeat messages enables the connector to send the latest retrieved LSN to the database, which allows the database to reclaim disk space being used by no longer needed WAL files.\n";
          type = (types.nullOr types.int);
        };
        "hstoreHandlingMode" = mkOption {
          description = "Default `json`. Specifies how the connector should handle values for hstore columns:\n\n* `map`: represents values by using MAP.\n* `json`: represents values by using json string. This setting encodes values as formatted strings such as {\"key\" : \"val\"}. For more information, see [PostgreSQL HSTORE type](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-hstore-type).\n";
          type = (types.nullOr types.str);
        };
        "includeUnknownDatatypes" = mkOption {
          description = "Default `true`. Specifies connector behavior when the connector encounters a field whose data type is unknown. The default behavior is that the connector omits the field from the change event and logs a warning.\n Set this property to true if you want the change event to contain an opaque binary representation of the field. This lets consumers decode the field. You can control the exact representation by setting the binaryHandlingMode property.\n> *NOTE*: Consumers risk backward compatibility issues when `includeUnknownDatatypes` is set to `true`. Not only may the database-specific binary representation change between releases, but if the data type is eventually supported by Debezium, the data type will be sent downstream in a logical type, which would require adjustments by consumers. In general, when encountering unsupported data types, create a feature request so that support can be added.\n";
          type = (types.nullOr types.bool);
        };
        "incrementalSnapshotChunkSize" = mkOption {
          description = "Default `1024`. The maximum number of rows that the connector fetches and reads into memory during an incremental snapshot chunk. Increasing the chunk size provides greater efficiency, because the snapshot runs fewer snapshot queries of a greater size. However, larger chunk sizes also require more memory to buffer the snapshot data. Adjust the chunk size to a value that provides the best performance in your environment.\n";
          type = (types.nullOr types.int);
        };
        "incrementalSnapshotWatermarkingStrategy" = mkOption {
          description = "Default `insert_insert`. Specifies the watermarking mechanism that the connector uses during an incremental snapshot to deduplicate events that might be captured by an incremental snapshot and then recaptured after streaming resumes.\n\nYou can specify one of the following options:\n\n* `insert_insert`: When you send a signal to initiate an incremental snapshot, for every chunk that Debezium reads during the snapshot, it writes an entry to the signaling data collection to record the signal to open the snapshot window. After the snapshot completes, Debezium inserts a second entry to record the closing of the window.\n* `insert_delete`: When you send a signal to initiate an incremental snapshot, for every chunk that Debezium reads, it writes a single entry to the signaling data collection to record the signal to open the snapshot window. After the snapshot completes, this entry is removed. No entry is created for the signal to close the snapshot window. Set this option to prevent rapid growth of the signaling data collection.\n";
          type = (types.nullOr types.str);
        };
        "intervalHandlingMode" = mkOption {
          description = "Default `numeric`. Specifies how the connector should handle values for interval columns:\n\n * `numeric`: represents intervals using approximate number of microseconds.\n * `string`: represents intervals exactly by using the string pattern representation P<years>Y<months>M<days>DT<hours>H<minutes>M<seconds>S. For example: P1Y2M3DT4H5M6.78S. For more information, see [PostgreSQL basic types](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-basic-types).\n";
          type = (types.nullOr types.str);
        };
        "maxBatchSize" = mkOption {
          description = "Default `2048`. Positive integer value that specifies the maximum size of each batch of events that the connector processes.\n";
          type = (types.nullOr types.int);
        };
        "maxQueueSize" = mkOption {
          description = "Default `8192`. Positive integer value that specifies the maximum number of records that the blocking queue can hold. When Debezium reads events streamed from the database, it places the events in the blocking queue before it writes/sends them. The blocking queue can provide backpressure for reading change events from the database in cases where the connector ingests messages faster than it can write / send them, or when target becomes unavailable. Events that are held in the queue are disregarded when the connector periodically records offsets. Always set the value of maxQueueSize to be larger than the value of maxBatchSize.\n";
          type = (types.nullOr types.int);
        };
        "maxQueueSizeInBytes" = mkOption {
          description = "Default `0`. A long integer value that specifies the maximum volume of the blocking queue in bytes. By default, volume limits are not specified for the blocking queue. To specify the number of bytes that the queue can consume, set this property to a positive long value.\n If maxQueueSize is also set, writing to the queue is blocked when the size of the queue reaches the limit specified by either property. For example, if you set maxQueueSize=1000, and maxQueueSizeInBytes=5000, writing to the queue is blocked after the queue contains 1000 records, or after the volume of the records in the queue reaches 5000 bytes.\n";
          type = (types.nullOr types.int);
        };
        "messageKeyColumns" = mkOption {
          description = "A list of expressions that specify the columns that the connector uses to form custom message keys for change event records that are publishes to the topics for specified tables.\n By default, Debezium uses the primary key column of a table as the message key for records that it emits. In place of the default, or to specify a key for tables that lack a primary key, you can configure custom message keys based on one or more columns.\n To establish a custom message key for a table, list the table, followed by the columns to use as the message key. Each list entry takes the following format:\n <fully-qualified_tableName>:<keyColumn>,<keyColumn>\n To base a table key on multiple column names, insert commas between the column names.\n Each fully-qualified table name is a regular expression in the following format:\n <schemaName>.<tableName>\n The property can include entries for multiple tables. Use a semicolon to separate table entries in the list.\n The following example sets the message key for the tables inventory.customers and purchase.orders:\n inventory.customers:pk1,pk2;(.*).purchaseorders:pk3,pk4\n For the table inventory.customer, the columns pk1 and pk2 are specified as the message key. For the purchaseorders tables in any schema, the columns pk3 and pk4 server as the message key.\n There is no limit to the number of columns that you use to create custom message keys. However, it’s best to use the minimum number that are required to specify a unique key.\n Note that having this property set and REPLICA IDENTITY set to DEFAULT on the tables, will cause the tombstone events to not be created properly if the key columns are not part of the primary key of the table. Setting REPLICA IDENTITY to FULL is the only solution.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "messagePrefixExcludeList" = mkOption {
          description = "An optional, comma-separated list of regular expressions that match the names of the logical decoding message prefixes that you do not want the connector to capture. When this property is set, the connector does not capture logical decoding messages that use the specified prefixes. All other messages are captured.\n\nTo exclude all logical decoding messages, set the value of this property to `.*`.\n\nTo match the name of a message prefix, Debezium applies the regular expression that you specify as an anchored regular expression. That is, the specified expression is matched against the entire message prefix string; the expression does not match substrings that might be present in a prefix.\n\nIf you include this property in the configuration, do not also set `messagePrefixIncludeList` property.\n\nFor information about the structure of message events and about their ordering semantics, see [message events](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-message-events).\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "messagePrefixIncludeList" = mkOption {
          description = "An optional, comma-separated list of regular expressions that match the names of the logical decoding message prefixes that you want the connector to capture. By default, the connector captures all logical decoding messages. When this property is set, the connector captures only logical decoding message with the prefixes specified by the property. All other logical decoding messages are excluded.\n\nTo match the name of a message prefix, Debezium applies the regular expression that you specify as an anchored regular expression. That is, the specified expression is matched against the entire message prefix string; the expression does not match substrings that might be present in a prefix.\n\nIf you include this property in the configuration, do not also set the `messagePrefixExcludeList` property.\n\nFor information about the structure of message events and about their ordering semantics, see [message events](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-message-events).\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "moneyFractionDigits" = mkOption {
          description = "Default `2`. Specifies how many decimal digits should be used when converting Postgres money type to java.math.BigDecimal, which represents the values in change events. Applicable only when decimalHandlingMode is set to precise.\n";
          type = (types.nullOr types.int);
        };
        "notificationEnabledChannels" = mkOption {
          description = "List of notification channel names that are enabled for the connector. By default, the following channels are available: sink, log and jmx. Optionally, you can also implement a [custom notification channel](https://debezium.io/documentation/reference/stable/configuration/signalling.html#debezium-signaling-enabling-custom-signaling-channel).\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "pluginName" = mkOption {
          description = "Default `pgoutput`. The name of the [PostgreSQL logical decoding plug-in](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-output-plugin) installed on the PostgreSQL server. Supported values are decoderbufs, and pgoutput.\n";
          type = (types.nullOr types.str);
        };
        "pollIntervalMs" = mkOption {
          description = "Default `500`. Positive integer value that specifies the number of milliseconds the connector should wait for new change events to appear before it starts processing a batch of events. Defaults to 500 milliseconds.\n";
          type = (types.nullOr types.int);
        };
        "provideTransactionMetadata" = mkOption {
          description = "Default `false`. Determines whether the connector generates events with transaction boundaries and enriches change event envelopes with transaction metadata. Specify true if you want the connector to do this. For more information, see [Transaction metadata](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-transaction-metadata).\n";
          type = (types.nullOr types.bool);
        };
        "publicationAutocreateMode" = mkOption {
          description = "Default `all_tables`. Applies only when streaming changes by using [the pgoutput plug-in](https://www.postgresql.org/docs/current/sql-createpublication.html). The setting determines how creation of a [publication](https://www.postgresql.org/docs/current/logical-replication-publication.html) should work. Specify one of the following values:\n\n* `all_tables` - If a publication exists, the connector uses it. If a publication does not exist, the connector creates a publication for all tables in the database for which the connector is capturing changes. For the connector to create a publication it must access the database through a database user account that has permission to create publications and perform replications. You grant the required permission by using the following SQL command CREATE PUBLICATION <publication_name> FOR ALL TABLES;.\n* `disabled` - The connector does not attempt to create a publication. A database administrator or the user configured to perform replications must have created the publication before running the connector. If the connector cannot find the publication, the connector throws an exception and stops.\n* `filtered` - If a publication exists, the connector uses it. If no publication exists, the connector creates a new publication for tables that match the current filter configuration as specified by the schema.include.list, schema.exclude.list, and table.include.list, and table.exclude.list connector configuration properties. For example: CREATE PUBLICATION <publication_name> FOR TABLE <tbl1, tbl2, tbl3>. If the publication exists, the connector updates the publication for tables that match the current filter configuration. For example: ALTER PUBLICATION <publication_name> SET TABLE <tbl1, tbl2, tbl3>.\n";
          type = (types.nullOr types.str);
        };
        "publicationName" = mkOption {
          description = "Default <SGStream name>.<SGStream namespace> (with all characters that are not `[a-zA-Z0-9]` changed to `_` character). The name of the PostgreSQL publication created for streaming changes when using pgoutput. This publication is created at start-up if it does not already exist and it includes all tables. Debezium then applies its own include/exclude list filtering, if configured, to limit the publication to change events for the specific tables of interest. The connector user must have superuser permissions to create this publication, so it is usually preferable to create the publication before starting the connector for the first time. If the publication already exists, either for all tables or configured with a subset of tables, Debezium uses the publication as it is defined.\n";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "Default `false`. Specifies whether a connector writes watermarks to the signal data collection to track the progress of an incremental snapshot. Set the value to `true` to enable a connector that has a read-only connection to the database to use an incremental snapshot watermarking strategy that does not require writing to the signal data collection.\n";
          type = (types.nullOr types.bool);
        };
        "replicaIdentityAutosetValues" = mkOption {
          description = "The setting determines the value for [replica identity](https://www.postgresql.org/docs/current/sql-altertable.html#SQL-ALTERTABLE-REPLICA-IDENTITY) at table level.\n  This option will overwrite the existing value in database. A comma-separated list of regular expressions that match fully-qualified tables and replica identity value to be used in the table.\n  Each expression must match the pattern '<fully-qualified table name>:<replica identity>', where the table name could be defined as (SCHEMA_NAME.TABLE_NAME), and the replica identity values are:\n  DEFAULT - Records the old values of the columns of the primary key, if any. This is the default for non-system tables.\n  INDEX index_name - Records the old values of the columns covered by the named index, that must be unique, not partial, not deferrable, and include only columns marked NOT NULL. If this index is dropped, the behavior is the same as NOTHING.\n  FULL - Records the old values of all columns in the row.\n  NOTHING - Records no information about the old row. This is the default for system tables.\n  For example,\n  schema1.*:FULL,schema2.table2:NOTHING,schema2.table3:INDEX idx_name\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "retriableRestartConnectorWaitMs" = mkOption {
          description = "Default `10000` (10 seconds). The number of milliseconds to wait before restarting a connector after a retriable error occurs.\n";
          type = (types.nullOr types.int);
        };
        "schemaNameAdjustmentMode" = mkOption {
          description = "Default `none`. Specifies how schema names should be adjusted for compatibility with the message converter used by the connector. Possible settings:\n\n* `none` does not apply any adjustment.\n* `avro` replaces the characters that cannot be used in the Avro type name with underscore.\n* `avro_unicode` replaces the underscore or characters that cannot be used in the Avro type name with corresponding unicode like _uxxxx. Note: _ is an escape sequence like backslash in Java\n";
          type = (types.nullOr types.str);
        };
        "schemaRefreshMode" = mkOption {
          description = "Default `columns_diff`. Specify the conditions that trigger a refresh of the in-memory schema for a table.\n\n* `columns_diff`: is the safest mode. It ensures that the in-memory schema stays in sync with the database table’s schema at all times.\n* `columns_diff_exclude_unchanged_toast`: instructs the connector to refresh the in-memory schema cache if there is a discrepancy with the schema derived from the incoming message, unless unchanged TOASTable data fully accounts for the discrepancy.\n\nThis setting can significantly improve connector performance if there are frequently-updated tables that have TOASTed data that are rarely part of updates. However, it is possible for the in-memory schema to become outdated if TOASTable columns are dropped from the table.\n";
          type = (types.nullOr types.str);
        };
        "signalDataCollection" = mkOption {
          description = "Fully-qualified name of the data collection that is used to send signals to the connector. Use the following format to specify the collection name: <schemaName>.<tableName>\n";
          type = (types.nullOr types.str);
        };
        "signalEnabledChannels" = mkOption {
          description = "Default `[sgstream-annotations]`. List of the signaling channel names that are enabled for the connector. By default, the following channels are available: sgstream-annotations, source, kafka, file and jmx. Optionally, you can also implement a [custom signaling channel](https://debezium.io/documentation/reference/stable/configuration/signalling.html#debezium-signaling-enabling-custom-signaling-channel).\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "skipMessagesWithoutChange" = mkOption {
          description = "Default `false`. Specifies whether to skip publishing messages when there is no change in included columns. This would essentially filter messages if there is no change in columns included as per includes or excludes fields. Note: Only works when REPLICA IDENTITY of the table is set to FULL\n";
          type = (types.nullOr types.bool);
        };
        "skippedOperations" = mkOption {
          description = "Default `none`. A list of operation types that will be skipped during streaming. The operations include: c for inserts/create, u for updates, d for deletes, t for truncates, and none to not skip any operations. By default, no operations are skipped.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "slotDropOnStop" = mkOption {
          description = "Default `true`. Whether or not to delete the logical replication slot when the connector stops in a graceful, expected way. The default behavior is that the replication slot remains configured for the connector when the connector stops. When the connector restarts, having the same replication slot enables the connector to start processing where it left off. Set to true in only testing or development environments. Dropping the slot allows the database to discard WAL segments. When the connector restarts it performs a new snapshot or it can continue from a persistent offset in the target offsets topic.\n";
          type = (types.nullOr types.bool);
        };
        "slotFailover" = mkOption {
          description = "Default `false'. Specifies whether the connector creates a failover slot. If you omit this setting, or if the primary server runs PostgreSQL 16 or earlier, the connector does not create a failover slot.\n\nPostgreSQL uses the `synchronized_standby_slots` parameter to configure replication slot synchronization between primary and standby servers. Set this parameter on the primary server to specify the physical replication slots that it synchronizes with on standby servers. \n";
          type = (types.nullOr types.bool);
        };
        "slotMaxRetries" = mkOption {
          description = "Default `6`. If connecting to a replication slot fails, this is the maximum number of consecutive attempts to connect.\n";
          type = (types.nullOr types.int);
        };
        "slotName" = mkOption {
          description = "Default <SGStream namespace>.<SGStream name> (with all characters that are not `[a-zA-Z0-9]` changed to `_` character). The name of the PostgreSQL logical decoding slot that was created for streaming changes from a particular plug-in for a particular database/schema. The server uses this slot to stream events to the Debezium connector that you are configuring.\n\nSlot names must conform to [PostgreSQL replication slot naming rules](https://www.postgresql.org/docs/current/static/warm-standby.html#STREAMING-REPLICATION-SLOTS-MANIPULATION), which state: \"Each replication slot has a name, which can contain lower-case letters, numbers, and the underscore character.\"\n";
          type = (types.nullOr types.str);
        };
        "slotRetryDelayMs" = mkOption {
          description = "Default `10000` (10 seconds). The number of milliseconds to wait between retry attempts when the connector fails to connect to a replication slot.\n";
          type = (types.nullOr types.int);
        };
        "slotStreamParams" = mkOption {
          description = "Parameters to pass to the configured logical decoding plug-in. For example:\n\n```\nslotStreamParams:\n  add-tables: \"public.table,public.table2\"\n  include-lsn: \"true\"\n```\n";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "snapshotDelayMs" = mkOption {
          description = "An interval in milliseconds that the connector should wait before performing a snapshot when the connector starts. If you are starting multiple connectors in a cluster, this property is useful for avoiding snapshot interruptions, which might cause re-balancing of connectors.\n";
          type = (types.nullOr types.int);
        };
        "snapshotFetchSize" = mkOption {
          description = "Default `10240`. During a snapshot, the connector reads table content in batches of rows. This property specifies the maximum number of rows in a batch.\n";
          type = (types.nullOr types.int);
        };
        "snapshotIncludeCollectionList" = mkOption {
          description = "Default <All tables / All tables filtered in `includes` field / All tables that are not filtered out in `excludes` field>. An optional, list of regular expressions that match the fully-qualified names (<schemaName>.<tableName>) of the tables to include in a snapshot. The specified items must be named in the connector’s table.include.list property. This property takes effect only if the connector’s snapshotMode property is set to a value other than `never`. This property does not affect the behavior of incremental snapshots.\n   To match the name of a table, Debezium applies the regular expression that you specify as an anchored regular expression. That is, the specified expression is matched against the entire name string of the table; it does not match substrings that might be present in a table name.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "snapshotIsolationMode" = mkOption {
          description = "Default `serializable`. Specifies the transaction isolation level and the type of locking, if any, that the connector applies when it reads data during an initial snapshot or ad hoc blocking snapshot.\n\nEach isolation level strikes a different balance between optimizing concurrency and performance on the one hand, and maximizing data consistency and accuracy on the other. Snapshots that use stricter isolation levels result in higher quality, more consistent data, but the cost of the improvement is decreased performance due to longer lock times and fewer concurrent transactions. Less restrictive isolation levels can increase efficiency, but at the expense of inconsistent data. For more information about transaction isolation levels in PostgreSQL, see the [PostgreSQL documentation](https://www.postgresql.org/docs/current/transaction-iso.html).\n\nSpecify one of the following isolation levels:\n\n* `serializable`: The default, and most restrictive isolation level. This option prevents serialization anomalies and provides the highest degree of data integrity. To ensure the data consistency of captured tables, a snapshot runs in a transaction that uses a repeatable read isolation level, blocking concurrent DDL changes on the tables, and locking the database to index creation. When this option is set, users or administrators cannot perform certain operations, such as creating a table index, until the snapshot concludes. The entire range of table keys remains locked until the snapshot completes. This option matches the snapshot behavior that was available in the connector before the introduction of this property.\n* `repeatable_read`: Prevents other transactions from updating table rows during the snapshot. New records captured by the snapshot can appear twice; first, as part of the initial snapshot, and then again in the streaming phase. However, this level of consistency is tolerable for database mirroring. Ensures data consistency between the tables being scanned and blocking DDL on the selected tables, and concurrent index creation throughout the database. Allows for serialization anomalies.\n* `read_committed`: In PostgreSQL, there is no difference between the behavior of the Read Uncommitted and Read Committed isolation modes. As a result, for this property, the read_committed option effectively provides the least restrictive level of isolation. Setting this option sacrifices some consistency for initial and ad hoc blocking snapshots, but provides better database performance for other users during the snapshot. In general, this transaction consistency level is appropriate for data mirroring. Other transactions cannot update table rows during the snapshot. However, minor data inconsistencies can occur when a record is added during the initial snapshot, and the connector later recaptures the record after the streaming phase begins.\n* `read_uncommitted`: Nominally, this option offers the least restrictive level of isolation. However, as explained in the description for the read-committed option, for the Debezium PostgreSQL connector, this option provides the same level of isolation as the read_committed option.\n";
          type = (types.nullOr types.str);
        };
        "snapshotLockTimeoutMs" = mkOption {
          description = "Default `10000`. Positive integer value that specifies the maximum amount of time (in milliseconds) to wait to obtain table locks when performing a snapshot. If the connector cannot acquire table locks in this time interval, the snapshot fails. [How the connector performs snapshots](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-snapshots) provides details.\n";
          type = (types.nullOr types.int);
        };
        "snapshotLockingMode" = mkOption {
          description = "Default `none`. Specifies how the connector holds locks on tables while performing a schema snapshot. Set one of the following options:\n\n* `shared`: The connector holds a table lock that prevents exclusive table access during the initial portion phase of the snapshot in which database schemas and other metadata are read. After the initial phase, the snapshot no longer requires table locks.\n* `none`: The connector avoids locks entirely. Do not use this mode if schema changes might occur during the snapshot.\n\n> *WARNING*: Do not use this mode if schema changes might occur during the snapshot.\n\n* `custom`: The connector performs a snapshot according to the implementation specified by the snapshotLockingModeCustomName property, which is a custom implementation of the io.debezium.spi.snapshot.SnapshotLock interface.\n";
          type = (types.nullOr types.str);
        };
        "snapshotLockingModeCustomName" = mkOption {
          description = "When snapshotLockingMode is set to custom, use this setting to specify the name of the custom implementation provided in the name() method that is defined by the 'io.debezium.spi.snapshot.SnapshotLock' interface. For more information, see [custom snapshotter SPI](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#connector-custom-snapshot).\n";
          type = (types.nullOr types.str);
        };
        "snapshotMaxThreads" = mkOption {
          description = "Default `1`. Specifies the number of threads that the connector uses when performing an initial snapshot. To enable parallel initial snapshots, set the property to a value greater than 1. In a parallel initial snapshot, the connector processes multiple tables concurrently. This feature is incubating.\n";
          type = (types.nullOr types.int);
        };
        "snapshotMode" = mkOption {
          description = "Default `initial`. Specifies the criteria for performing a snapshot when the connector starts:\n\n* `always` - The connector performs a snapshot every time that it starts. The snapshot includes the structure and data of the captured tables. Specify this value to populate topics with a complete representation of the data from the captured tables every time that the connector starts. After the snapshot completes, the connector begins to stream event records for subsequent database changes.\n* `initial` - The connector performs a snapshot only when no offsets have been recorded for the logical server name.\n* `initial_only` - The connector performs an initial snapshot and then stops, without processing any subsequent changes.\n* `no_data` - The connector never performs snapshots. When a connector is configured this way, after it starts, it behaves as follows: If there is a previously stored LSN in the offsets topic, the connector continues streaming changes from that position. If no LSN is stored, the connector starts streaming changes from the point in time when the PostgreSQL logical replication slot was created on the server. Use this snapshot mode only when you know all data of interest is still reflected in the WAL.\n* `never` - Deprecated see no_data.\n* `when_needed` - After the connector starts, it performs a snapshot only if it detects one of the following circumstances: \n  It cannot detect any topic offsets.\n  A previously recorded offset specifies a log position that is not available on the server.\n* `configuration_based` - With this option, you control snapshot behavior through a set of connector properties that have the prefix 'snapshotModeConfigurationBased'.\n* `custom` - The connector performs a snapshot according to the implementation specified by the snapshotModeCustomName property, which defines a custom implementation of the io.debezium.spi.snapshot.Snapshotter interface.\n\nFor more information, see the [table of snapshot.mode options](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-connector-snapshot-mode-options).\n";
          type = (types.nullOr types.str);
        };
        "snapshotModeConfigurationBasedSnapshotData" = mkOption {
          description = "Default `false`. If the snapshotMode is set to configuration_based, set this property to specify whether the connector includes table data when it performs a snapshot.\n";
          type = (types.nullOr types.bool);
        };
        "snapshotModeConfigurationBasedSnapshotOnDataError" = mkOption {
          description = "Default `false`. If the snapshotMode is set to configuration_based, this property specifies whether the connector attempts to snapshot table data if it does not find the last committed offset in the transaction log. Set the value to true to instruct the connector to perform a new snapshot.\n";
          type = (types.nullOr types.bool);
        };
        "snapshotModeConfigurationBasedSnapshotOnSchemaError" = mkOption {
          description = "Default `false`. If the snapshotMode is set to configuration_based, set this property to specify whether the connector includes table schema in a snapshot if the schema history topic is not available.\n";
          type = (types.nullOr types.bool);
        };
        "snapshotModeConfigurationBasedSnapshotSchema" = mkOption {
          description = "Default `false`. If the snapshotMode is set to configuration_based, set this property to specify whether the connector includes the table schema when it performs a snapshot.\n";
          type = (types.nullOr types.bool);
        };
        "snapshotModeConfigurationBasedStartStream" = mkOption {
          description = "Default `false`. If the snapshotMode is set to configuration_based, set this property to specify whether the connector begins to stream change events after a snapshot completes.\n";
          type = (types.nullOr types.bool);
        };
        "snapshotModeCustomName" = mkOption {
          description = "When snapshotMode is set as custom, use this setting to specify the name of the custom implementation provided in the name() method that is defined by the 'io.debezium.spi.snapshot.Snapshotter' interface. The provided implementation is called after a connector restart to determine whether to perform a snapshot. For more information, see [custom snapshotter SPI](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#connector-custom-snapshot).\n";
          type = (types.nullOr types.str);
        };
        "snapshotQueryMode" = mkOption {
          description = "Default `select_all`. Specifies how the connector queries data while performing a snapshot. Set one of the following options:\n\n* `select_all`: The connector performs a select all query by default, optionally adjusting the columns selected based on the column include and exclude list configurations.\n* `custom`: The connector performs a snapshot query according to the implementation specified by the snapshotQueryModeCustomName property, which defines a custom implementation of the io.debezium.spi.snapshot.SnapshotQuery interface. This setting enables you to manage snapshot content in a more flexible manner compared to using the snapshotSelectStatementOverrides property.\n";
          type = (types.nullOr types.str);
        };
        "snapshotQueryModeCustomName" = mkOption {
          description = "When snapshotQueryMode is set as custom, use this setting to specify the name of the custom implementation provided in the name() method that is defined by the 'io.debezium.spi.snapshot.SnapshotQuery' interface. For more information, see [custom snapshotter SPI](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#connector-custom-snapshot).\n";
          type = (types.nullOr types.str);
        };
        "snapshotSelectStatementOverrides" = mkOption {
          description = "Specifies the table rows to include in a snapshot. Use the property if you want a snapshot to include only a subset of the rows in a table. This property affects snapshots only. It does not apply to events that the connector reads from the log.\n The property contains a hierarchy of fully-qualified table names in the form <schemaName>.<tableName>. For example,\n\n```\nsnapshotSelectStatementOverrides: \n  \"customers.orders\": \"SELECT * FROM [customers].[orders] WHERE delete_flag = 0 ORDER BY id DESC\"\n```\n\nIn the resulting snapshot, the connector includes only the records for which delete_flag = 0.\n";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "statusUpdateIntervalMs" = mkOption {
          description = "Default `10000`. Frequency for sending replication connection status updates to the server, given in milliseconds. The property also controls how frequently the database status is checked to detect a dead connection in case the database was shut down.\n";
          type = (types.nullOr types.int);
        };
        "timePrecisionMode" = mkOption {
          description = "Default `adaptive`. Time, date, and timestamps can be represented with different kinds of precision:\n\n* `adaptive`: captures the time and timestamp values exactly as in the database using either millisecond, microsecond, or nanosecond precision values based on the database column’s type.\n* `adaptive_time_microseconds`: captures the date, datetime and timestamp values exactly as in the database using either millisecond, microsecond, or nanosecond precision values based on the database column’s type. An exception is TIME type fields, which are always captured as microseconds.\n* `connect`: always represents time and timestamp values by using Kafka Connect’s built-in representations for Time, Date, and Timestamp, which use millisecond precision regardless of the database columns' precision. For more information, see [temporal values](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-temporal-types).\n";
          type = (types.nullOr types.str);
        };
        "tombstonesOnDelete" = mkOption {
          description = "Default `true`. Controls whether a delete event is followed by a tombstone event.\n\n* `true` - a delete operation is represented by a delete event and a subsequent tombstone event.\n* `false` - only a delete event is emitted.\n\nAfter a source record is deleted, emitting a tombstone event (the default behavior) allows to completely delete all events that pertain to the key of the deleted row in case [log compaction](https://kafka.apache.org/documentation/#compaction) is enabled for the topic.\n";
          type = (types.nullOr types.bool);
        };
        "topicCacheSize" = mkOption {
          description = "Default `10000`. The size used for holding the topic names in bounded concurrent hash map. This cache will help to determine the topic name corresponding to a given data collection.\n";
          type = (types.nullOr types.int);
        };
        "topicDelimiter" = mkOption {
          description = "Default `.`. Specify the delimiter for topic name, defaults to \".\".\n";
          type = (types.nullOr types.str);
        };
        "topicHeartbeatPrefix" = mkOption {
          description = "Default `__debezium-heartbeat`. Controls the name of the topic to which the connector sends heartbeat messages. For example, if the topic prefix is fulfillment, the default topic name is __debezium-heartbeat.fulfillment.\n";
          type = (types.nullOr types.str);
        };
        "topicNamingStrategy" = mkOption {
          description = "Default `io.debezium.schema.SchemaTopicNamingStrategy`. The name of the TopicNamingStrategy class that should be used to determine the topic name for data change, schema change, transaction, heartbeat event etc., defaults to SchemaTopicNamingStrategy.\n";
          type = (types.nullOr types.str);
        };
        "topicTransaction" = mkOption {
          description = "Default `transaction`. Controls the name of the topic to which the connector sends transaction metadata messages. For example, if the topic prefix is fulfillment, the default topic name is fulfillment.transaction.\n";
          type = (types.nullOr types.str);
        };
        "unavailableValuePlaceholder" = mkOption {
          description = "Default `__debezium_unavailable_value`. Specifies the constant that the connector provides to indicate that the original value is a toasted value that is not provided by the database. If the setting of unavailable.value.placeholder starts with the hex: prefix it is expected that the rest of the string represents hexadecimally encoded octets. For more information, see [toasted values](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-toasted-values).\n";
          type = (types.nullOr types.str);
        };
        "xminFetchIntervalMs" = mkOption {
          description = "Default `0`. How often, in milliseconds, the XMIN will be read from the replication slot. The XMIN value provides the lower bounds of where a new replication slot could start from. The default value of 0 disables tracking XMIN tracking.\n";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "binaryHandlingMode" = mkOverride 1002 null;
        "columnMaskHash" = mkOverride 1002 null;
        "columnMaskHashV2" = mkOverride 1002 null;
        "columnMaskWithLengthChars" = mkOverride 1002 null;
        "columnPropagateSourceType" = mkOverride 1002 null;
        "columnTruncateToLengthChars" = mkOverride 1002 null;
        "converters" = mkOverride 1002 null;
        "customMetricTags" = mkOverride 1002 null;
        "databaseInitialStatements" = mkOverride 1002 null;
        "databaseQueryTimeoutMs" = mkOverride 1002 null;
        "datatypePropagateSourceType" = mkOverride 1002 null;
        "decimalHandlingMode" = mkOverride 1002 null;
        "errorsMaxRetries" = mkOverride 1002 null;
        "eventProcessingFailureHandlingMode" = mkOverride 1002 null;
        "fieldNameAdjustmentMode" = mkOverride 1002 null;
        "flushLsnSource" = mkOverride 1002 null;
        "heartbeatActionQuery" = mkOverride 1002 null;
        "heartbeatIntervalMs" = mkOverride 1002 null;
        "hstoreHandlingMode" = mkOverride 1002 null;
        "includeUnknownDatatypes" = mkOverride 1002 null;
        "incrementalSnapshotChunkSize" = mkOverride 1002 null;
        "incrementalSnapshotWatermarkingStrategy" = mkOverride 1002 null;
        "intervalHandlingMode" = mkOverride 1002 null;
        "maxBatchSize" = mkOverride 1002 null;
        "maxQueueSize" = mkOverride 1002 null;
        "maxQueueSizeInBytes" = mkOverride 1002 null;
        "messageKeyColumns" = mkOverride 1002 null;
        "messagePrefixExcludeList" = mkOverride 1002 null;
        "messagePrefixIncludeList" = mkOverride 1002 null;
        "moneyFractionDigits" = mkOverride 1002 null;
        "notificationEnabledChannels" = mkOverride 1002 null;
        "pluginName" = mkOverride 1002 null;
        "pollIntervalMs" = mkOverride 1002 null;
        "provideTransactionMetadata" = mkOverride 1002 null;
        "publicationAutocreateMode" = mkOverride 1002 null;
        "publicationName" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "replicaIdentityAutosetValues" = mkOverride 1002 null;
        "retriableRestartConnectorWaitMs" = mkOverride 1002 null;
        "schemaNameAdjustmentMode" = mkOverride 1002 null;
        "schemaRefreshMode" = mkOverride 1002 null;
        "signalDataCollection" = mkOverride 1002 null;
        "signalEnabledChannels" = mkOverride 1002 null;
        "skipMessagesWithoutChange" = mkOverride 1002 null;
        "skippedOperations" = mkOverride 1002 null;
        "slotDropOnStop" = mkOverride 1002 null;
        "slotFailover" = mkOverride 1002 null;
        "slotMaxRetries" = mkOverride 1002 null;
        "slotName" = mkOverride 1002 null;
        "slotRetryDelayMs" = mkOverride 1002 null;
        "slotStreamParams" = mkOverride 1002 null;
        "snapshotDelayMs" = mkOverride 1002 null;
        "snapshotFetchSize" = mkOverride 1002 null;
        "snapshotIncludeCollectionList" = mkOverride 1002 null;
        "snapshotIsolationMode" = mkOverride 1002 null;
        "snapshotLockTimeoutMs" = mkOverride 1002 null;
        "snapshotLockingMode" = mkOverride 1002 null;
        "snapshotLockingModeCustomName" = mkOverride 1002 null;
        "snapshotMaxThreads" = mkOverride 1002 null;
        "snapshotMode" = mkOverride 1002 null;
        "snapshotModeConfigurationBasedSnapshotData" = mkOverride 1002 null;
        "snapshotModeConfigurationBasedSnapshotOnDataError" = mkOverride 1002 null;
        "snapshotModeConfigurationBasedSnapshotOnSchemaError" = mkOverride 1002 null;
        "snapshotModeConfigurationBasedSnapshotSchema" = mkOverride 1002 null;
        "snapshotModeConfigurationBasedStartStream" = mkOverride 1002 null;
        "snapshotModeCustomName" = mkOverride 1002 null;
        "snapshotQueryMode" = mkOverride 1002 null;
        "snapshotQueryModeCustomName" = mkOverride 1002 null;
        "snapshotSelectStatementOverrides" = mkOverride 1002 null;
        "statusUpdateIntervalMs" = mkOverride 1002 null;
        "timePrecisionMode" = mkOverride 1002 null;
        "tombstonesOnDelete" = mkOverride 1002 null;
        "topicCacheSize" = mkOverride 1002 null;
        "topicDelimiter" = mkOverride 1002 null;
        "topicHeartbeatPrefix" = mkOverride 1002 null;
        "topicNamingStrategy" = mkOverride 1002 null;
        "topicTransaction" = mkOverride 1002 null;
        "unavailableValuePlaceholder" = mkOverride 1002 null;
        "xminFetchIntervalMs" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecSourcePostgresPassword" = {

      options = {
        "key" = mkOption {
          description = "The Secret key where the password is stored.\n";
          type = types.str;
        };
        "name" = mkOption {
          description = "The Secret name where the password is stored.\n";
          type = types.str;
        };
      };

      config = { };

    };
    "stackgres.io.v1alpha1.SGStreamSpecSourcePostgresUsername" = {

      options = {
        "key" = mkOption {
          description = "The Secret key where the username is stored.\n";
          type = types.str;
        };
        "name" = mkOption {
          description = "The Secret name where the username is stored.\n";
          type = types.str;
        };
      };

      config = { };

    };
    "stackgres.io.v1alpha1.SGStreamSpecSourceSgCluster" = {

      options = {
        "database" = mkOption {
          description = "The target database name to which the CDC process will connect to.\n\nIf not specified the default postgres database will be targeted.\n";
          type = (types.nullOr types.str);
        };
        "debeziumProperties" = mkOption {
          description = "Specific property of the debezium Postgres connector.\n\nSee https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-connector-properties\n\nEach property is converted from myPropertyName to my.property.name\n";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecSourceSgClusterDebeziumProperties")
          );
        };
        "excludes" = mkOption {
          description = "A list of regular expressions that allow to match one or more `<schema>.<table>.<column>` entries to be filtered out before sending to the target.\n\nThis property is mutually exclusive with `includes`.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "includes" = mkOption {
          description = "A list of regular expressions that allow to match one or more `<schema>.<table>.<column>` entries to be filtered before sending to the target.\n\nThis property is mutually exclusive with `excludes`.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "name" = mkOption {
          description = "The target SGCluster name.\n";
          type = types.str;
        };
        "password" = mkOption {
          description = "The password used by the CDC process to connect to the database.\n\nIf not specified the default superuser password will be used.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecSourceSgClusterPassword"));
        };
        "skipDropReplicationSlotAndPublicationOnTombstone" = mkOption {
          description = "When set to `true` replication slot and publication will not be dropped after receiving the tombstone signal.";
          type = (types.nullOr types.bool);
        };
        "username" = mkOption {
          description = "The username used by the CDC process to connect to the database.\n\nIf not specified the default superuser username (by default postgres) will be used.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecSourceSgClusterUsername"));
        };
      };

      config = {
        "database" = mkOverride 1002 null;
        "debeziumProperties" = mkOverride 1002 null;
        "excludes" = mkOverride 1002 null;
        "includes" = mkOverride 1002 null;
        "password" = mkOverride 1002 null;
        "skipDropReplicationSlotAndPublicationOnTombstone" = mkOverride 1002 null;
        "username" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecSourceSgClusterDebeziumProperties" = {

      options = {
        "binaryHandlingMode" = mkOption {
          description = "Default `bytes`. Specifies how binary (bytea) columns should be represented in change events:\n\n* `bytes` represents binary data as byte array.\n* `base64` represents binary data as base64-encoded strings.\n* `base64-url-safe` represents binary data as base64-url-safe-encoded strings.\n* `hex` represents binary data as hex-encoded (base16) strings.\n";
          type = (types.nullOr types.str);
        };
        "columnMaskHash" = mkOption {
          description = "An optional section, that allow to specify, for an hash algorithm and a salt, a list of regular expressions that match the fully-qualified names of character-based columns. Fully-qualified names for columns are of the form <schemaName>.<tableName>.<columnName>.\n To match the name of a column Debezium applies the regular expression that you specify as an anchored regular expression. That is, the specified expression is matched against the entire name string of the column; the expression does not match substrings that might be present in a column name. In the resulting change event record, the values for the specified columns are replaced with pseudonyms.\n A pseudonym consists of the hashed value that results from applying the specified hashAlgorithm and salt. Based on the hash function that is used, referential integrity is maintained, while column values are replaced with pseudonyms. Supported hash functions are described in the [MessageDigest section](https://docs.oracle.com/javase/7/docs/technotes/guides/security/StandardNames.html#MessageDigest) of the Java Cryptography Architecture Standard Algorithm Name Documentation.\n In the following example, CzQMA0cB5K is a randomly selected salt.\n columnMaskHash.SHA-256.CzQMA0cB5K=[inventory.orders.customerName,inventory.shipment.customerName]\n If necessary, the pseudonym is automatically shortened to the length of the column. The connector configuration can include multiple properties that specify different hash algorithms and salts.\n Depending on the hash algorithm used, the salt selected, and the actual data set, the resulting data set might not be completely masked.\n";
          type = (types.nullOr (types.attrsOf types.attrs));
        };
        "columnMaskHashV2" = mkOption {
          description = "Similar to also columnMaskHash but using hashing strategy version 2.\n Hashing strategy version 2 should be used to ensure fidelity if the value is being hashed in different places or systems.\n";
          type = (types.nullOr (types.attrsOf types.attrs));
        };
        "columnMaskWithLengthChars" = mkOption {
          description = "An optional, list of regular expressions that match the fully-qualified names of character-based columns. Set this property if you want the connector to mask the values for a set of columns, for example, if they contain sensitive data. Set length to a positive integer to replace data in the specified columns with the number of asterisk (*) characters specified by the length in the property name. Set length to 0 (zero) to replace data in the specified columns with an empty string.\n The fully-qualified name of a column observes the following format: schemaName.tableName.columnName.\n To match the name of a column, Debezium applies the regular expression that you specify as an anchored regular expression. That is, the specified expression is matched against the entire name string of the column; the expression does not match substrings that might be present in a column name.\n You can specify multiple properties with different lengths in a single configuration.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "columnPropagateSourceType" = mkOption {
          description = "Default `[.*]`. An optional, list of regular expressions that match the fully-qualified names of columns for which you want the connector to emit extra parameters that represent column metadata. When this property is set, the connector adds the following fields to the schema of event records:\n\n* `__debezium.source.column.type`\n* `__debezium.source.column.length`\n* `__debezium.source.column.scale`\n\nThese parameters propagate a column’s original type name and length (for variable-width types), respectively.\n Enabling the connector to emit this extra data can assist in properly sizing specific numeric or character-based columns in sink databases.\n The fully-qualified name of a column observes one of the following formats: databaseName.tableName.columnName, or databaseName.schemaName.tableName.columnName.\n To match the name of a column, Debezium applies the regular expression that you specify as an anchored regular expression. That is, the specified expression is matched against the entire name string of the column; the expression does not match substrings that might be present in a column name.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "columnTruncateToLengthChars" = mkOption {
          description = "An optional, list of regular expressions that match the fully-qualified names of character-based columns. Set this property if you want to truncate the data in a set of columns when it exceeds the number of characters specified by the length in the property name. Set length to a positive integer value, for example, column.truncate.to.20.chars.\n The fully-qualified name of a column observes the following format: <schemaName>.<tableName>.<columnName>.\n To match the name of a column, Debezium applies the regular expression that you specify as an anchored regular expression. That is, the specified expression is matched against the entire name string of the column; the expression does not match substrings that might be present in a column name.\n You can specify multiple properties with different lengths in a single configuration.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "converters" = mkOption {
          description = "Enumerates a comma-separated list of the symbolic names of the [custom converter](https://debezium.io/documentation/reference/stable/development/converters.html#custom-converters) instances that the connector can use. For example,\n\n```\nisbn:\n  type: io.debezium.test.IsbnConverter\n  schemaName: io.debezium.postgresql.type.Isbn\n```\n\nYou must set the converters property to enable the connector to use a custom converter.\n For each converter that you configure for a connector, you must also add a .type property, which specifies the fully-qualified name of the class that implements the converter interface.\nIf you want to further control the behavior of a configured converter, you can add one or more configuration parameters to pass values to the converter. To associate any additional configuration parameter with a converter, prefix the parameter names with the symbolic name of the converter.\n Each property is converted from myPropertyName to my.property.name\n";
          type = (types.nullOr (types.attrsOf types.attrs));
        };
        "customMetricTags" = mkOption {
          description = "The custom metric tags will accept key-value pairs to customize the MBean object name which should be appended the end of regular name, each key would represent a tag for the MBean object name, and the corresponding value would be the value of that tag the key is. For example:\n\n```\ncustomMetricTags:\n  k1: v1\n  k2: v2\n```\n";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "databaseInitialStatements" = mkOption {
          description = "A list of SQL statements that the connector executes when it establishes a JDBC connection to the database.\n The connector may establish JDBC connections at its own discretion. Consequently, this property is useful for configuration of session parameters only, and not for executing DML statements.\n The connector does not execute these statements when it creates a connection for reading the transaction log.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "databaseQueryTimeoutMs" = mkOption {
          description = "Default `0`. Specifies the time, in milliseconds, that the connector waits for a query to complete. Set the value to 0 (zero) to remove the timeout limit.\n";
          type = (types.nullOr types.int);
        };
        "datatypePropagateSourceType" = mkOption {
          description = "Default `[.*]`. An optional, list of regular expressions that specify the fully-qualified names of data types that are defined for columns in a database. When this property is set, for columns with matching data types, the connector emits event records that include the following extra fields in their schema:\n\n* `__debezium.source.column.type`\n* `__debezium.source.column.length`\n* `__debezium.source.column.scale`\n\nThese parameters propagate a column’s original type name and length (for variable-width types), respectively.\n Enabling the connector to emit this extra data can assist in properly sizing specific numeric or character-based columns in sink databases.\n The fully-qualified name of a column observes one of the following formats: databaseName.tableName.typeName, or databaseName.schemaName.tableName.typeName.\n To match the name of a data type, Debezium applies the regular expression that you specify as an anchored regular expression. That is, the specified expression is matched against the entire name string of the data type; the expression does not match substrings that might be present in a type name.\n For the list of PostgreSQL-specific data type names, see the [PostgreSQL data type mappings](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-data-types).\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "decimalHandlingMode" = mkOption {
          description = "Default `precise`. Specifies how the connector should handle values for DECIMAL and NUMERIC columns:\n\n* `precise`: represents values by using java.math.BigDecimal to represent values in binary form in change events.\n* `double`: represents values by using double values, which might result in a loss of precision but which is easier to use.\n* `string`: encodes values as formatted strings, which are easy to consume but semantic information about the real type is lost. For more information, see [Decimal types](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-decimal-types).\n";
          type = (types.nullOr types.str);
        };
        "errorsMaxRetries" = mkOption {
          description = "Default `-1`. Specifies how the connector responds after an operation that results in a retriable error, such as a connection error.\n\nSet one of the following options:\n\n* `-1`: No limit. The connector always restarts automatically, and retries the operation, regardless of the number of previous failures.\n* `0`: Disabled. The connector fails immediately, and never retries the operation. User intervention is required to restart the connector.\n* `> 0`: The connector restarts automatically until it reaches the specified maximum number of retries. After the next failure, the connector stops, and user intervention is required to restart it.\n";
          type = (types.nullOr types.int);
        };
        "eventProcessingFailureHandlingMode" = mkOption {
          description = "Default `fail`. Specifies how the connector should react to exceptions during processing of events:\n\n* `fail`: propagates the exception, indicates the offset of the problematic event, and causes the connector to stop.\n* `warn`: logs the offset of the problematic event, skips that event, and continues processing.\n* `skip`: skips the problematic event and continues processing.\n";
          type = (types.nullOr types.str);
        };
        "fieldNameAdjustmentMode" = mkOption {
          description = "Default `none`. Specifies how field names should be adjusted for compatibility with the message converter used by the connector. Possible settings:\n\n* `none` does not apply any adjustment.\n* `avro` replaces the characters that cannot be used in the Avro type name with underscore.\n* `avro_unicode` replaces the underscore or characters that cannot be used in the Avro type name with corresponding unicode like _uxxxx. Note: _ is an escape sequence like backslash in Java\n\nFor more information, see [Avro naming](https://debezium.io/documentation/reference/stable/configuration/avro.html#avro-naming).\n";
          type = (types.nullOr types.str);
        };
        "flushLsnSource" = mkOption {
          description = "Default `true`. Determines whether the connector should commit the LSN of the processed records in the source postgres database so that the WAL logs can be deleted. Specify false if you don’t want the connector to do this. Please note that if set to false LSN will not be acknowledged by Debezium and as a result WAL logs will not be cleared which might result in disk space issues. User is expected to handle the acknowledgement of LSN outside Debezium.\n";
          type = (types.nullOr types.bool);
        };
        "heartbeatActionQuery" = mkOption {
          description = "Specifies a query that the connector executes on the source database when the connector sends a heartbeat message.\n This is useful for resolving the situation described in [WAL disk space consumption](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-wal-disk-space), where capturing changes from a low-traffic database on the same host as a high-traffic database prevents Debezium from processing WAL records and thus acknowledging WAL positions with the database. To address this situation, create a heartbeat table in the low-traffic database, and set this property to a statement that inserts records into that table, for example:\n\n ```\n INSERT INTO test_heartbeat_table (text) VALUES ('test_heartbeat')\n ```\n \n This allows the connector to receive changes from the low-traffic database and acknowledge their LSNs, which prevents unbounded WAL growth on the database host.\n";
          type = (types.nullOr types.str);
        };
        "heartbeatIntervalMs" = mkOption {
          description = "Default `0`. Controls how frequently the connector sends heartbeat messages to a target topic. The default behavior is that the connector does not send heartbeat messages.\n Heartbeat messages are useful for monitoring whether the connector is receiving change events from the database. Heartbeat messages might help decrease the number of change events that need to be re-sent when a connector restarts. To send heartbeat messages, set this property to a positive integer, which indicates the number of milliseconds between heartbeat messages.\n Heartbeat messages are needed when there are many updates in a database that is being tracked but only a tiny number of updates are related to the table(s) and schema(s) for which the connector is capturing changes. In this situation, the connector reads from the database transaction log as usual but rarely emits change records to target. This means that no offset updates are committed to target and the connector does not have an opportunity to send the latest retrieved LSN to the database. The database retains WAL files that contain events that have already been processed by the connector. Sending heartbeat messages enables the connector to send the latest retrieved LSN to the database, which allows the database to reclaim disk space being used by no longer needed WAL files.\n";
          type = (types.nullOr types.int);
        };
        "hstoreHandlingMode" = mkOption {
          description = "Default `json`. Specifies how the connector should handle values for hstore columns:\n\n* `map`: represents values by using MAP.\n* `json`: represents values by using json string. This setting encodes values as formatted strings such as {\"key\" : \"val\"}. For more information, see [PostgreSQL HSTORE type](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-hstore-type).\n";
          type = (types.nullOr types.str);
        };
        "includeUnknownDatatypes" = mkOption {
          description = "Default `true`. Specifies connector behavior when the connector encounters a field whose data type is unknown. The default behavior is that the connector omits the field from the change event and logs a warning.\n Set this property to true if you want the change event to contain an opaque binary representation of the field. This lets consumers decode the field. You can control the exact representation by setting the binaryHandlingMode property.\n> *NOTE*: Consumers risk backward compatibility issues when `includeUnknownDatatypes` is set to `true`. Not only may the database-specific binary representation change between releases, but if the data type is eventually supported by Debezium, the data type will be sent downstream in a logical type, which would require adjustments by consumers. In general, when encountering unsupported data types, create a feature request so that support can be added.\n";
          type = (types.nullOr types.bool);
        };
        "incrementalSnapshotChunkSize" = mkOption {
          description = "Default `1024`. The maximum number of rows that the connector fetches and reads into memory during an incremental snapshot chunk. Increasing the chunk size provides greater efficiency, because the snapshot runs fewer snapshot queries of a greater size. However, larger chunk sizes also require more memory to buffer the snapshot data. Adjust the chunk size to a value that provides the best performance in your environment.\n";
          type = (types.nullOr types.int);
        };
        "incrementalSnapshotWatermarkingStrategy" = mkOption {
          description = "Default `insert_insert`. Specifies the watermarking mechanism that the connector uses during an incremental snapshot to deduplicate events that might be captured by an incremental snapshot and then recaptured after streaming resumes.\n\nYou can specify one of the following options:\n\n* `insert_insert`: When you send a signal to initiate an incremental snapshot, for every chunk that Debezium reads during the snapshot, it writes an entry to the signaling data collection to record the signal to open the snapshot window. After the snapshot completes, Debezium inserts a second entry to record the closing of the window.\n* `insert_delete`: When you send a signal to initiate an incremental snapshot, for every chunk that Debezium reads, it writes a single entry to the signaling data collection to record the signal to open the snapshot window. After the snapshot completes, this entry is removed. No entry is created for the signal to close the snapshot window. Set this option to prevent rapid growth of the signaling data collection.\n";
          type = (types.nullOr types.str);
        };
        "intervalHandlingMode" = mkOption {
          description = "Default `numeric`. Specifies how the connector should handle values for interval columns:\n\n * `numeric`: represents intervals using approximate number of microseconds.\n * `string`: represents intervals exactly by using the string pattern representation P<years>Y<months>M<days>DT<hours>H<minutes>M<seconds>S. For example: P1Y2M3DT4H5M6.78S. For more information, see [PostgreSQL basic types](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-basic-types).\n";
          type = (types.nullOr types.str);
        };
        "maxBatchSize" = mkOption {
          description = "Default `2048`. Positive integer value that specifies the maximum size of each batch of events that the connector processes.\n";
          type = (types.nullOr types.int);
        };
        "maxQueueSize" = mkOption {
          description = "Default `8192`. Positive integer value that specifies the maximum number of records that the blocking queue can hold. When Debezium reads events streamed from the database, it places the events in the blocking queue before it writes/sends them. The blocking queue can provide backpressure for reading change events from the database in cases where the connector ingests messages faster than it can write / send them, or when target becomes unavailable. Events that are held in the queue are disregarded when the connector periodically records offsets. Always set the value of maxQueueSize to be larger than the value of maxBatchSize.\n";
          type = (types.nullOr types.int);
        };
        "maxQueueSizeInBytes" = mkOption {
          description = "Default `0`. A long integer value that specifies the maximum volume of the blocking queue in bytes. By default, volume limits are not specified for the blocking queue. To specify the number of bytes that the queue can consume, set this property to a positive long value.\n If maxQueueSize is also set, writing to the queue is blocked when the size of the queue reaches the limit specified by either property. For example, if you set maxQueueSize=1000, and maxQueueSizeInBytes=5000, writing to the queue is blocked after the queue contains 1000 records, or after the volume of the records in the queue reaches 5000 bytes.\n";
          type = (types.nullOr types.int);
        };
        "messageKeyColumns" = mkOption {
          description = "A list of expressions that specify the columns that the connector uses to form custom message keys for change event records that are publishes to the topics for specified tables.\n By default, Debezium uses the primary key column of a table as the message key for records that it emits. In place of the default, or to specify a key for tables that lack a primary key, you can configure custom message keys based on one or more columns.\n To establish a custom message key for a table, list the table, followed by the columns to use as the message key. Each list entry takes the following format:\n <fully-qualified_tableName>:<keyColumn>,<keyColumn>\n To base a table key on multiple column names, insert commas between the column names.\n Each fully-qualified table name is a regular expression in the following format:\n <schemaName>.<tableName>\n The property can include entries for multiple tables. Use a semicolon to separate table entries in the list.\n The following example sets the message key for the tables inventory.customers and purchase.orders:\n inventory.customers:pk1,pk2;(.*).purchaseorders:pk3,pk4\n For the table inventory.customer, the columns pk1 and pk2 are specified as the message key. For the purchaseorders tables in any schema, the columns pk3 and pk4 server as the message key.\n There is no limit to the number of columns that you use to create custom message keys. However, it’s best to use the minimum number that are required to specify a unique key.\n Note that having this property set and REPLICA IDENTITY set to DEFAULT on the tables, will cause the tombstone events to not be created properly if the key columns are not part of the primary key of the table. Setting REPLICA IDENTITY to FULL is the only solution.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "messagePrefixExcludeList" = mkOption {
          description = "An optional, comma-separated list of regular expressions that match the names of the logical decoding message prefixes that you do not want the connector to capture. When this property is set, the connector does not capture logical decoding messages that use the specified prefixes. All other messages are captured.\n\nTo exclude all logical decoding messages, set the value of this property to `.*`.\n\nTo match the name of a message prefix, Debezium applies the regular expression that you specify as an anchored regular expression. That is, the specified expression is matched against the entire message prefix string; the expression does not match substrings that might be present in a prefix.\n\nIf you include this property in the configuration, do not also set `messagePrefixIncludeList` property.\n\nFor information about the structure of message events and about their ordering semantics, see [message events](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-message-events).\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "messagePrefixIncludeList" = mkOption {
          description = "An optional, comma-separated list of regular expressions that match the names of the logical decoding message prefixes that you want the connector to capture. By default, the connector captures all logical decoding messages. When this property is set, the connector captures only logical decoding message with the prefixes specified by the property. All other logical decoding messages are excluded.\n\nTo match the name of a message prefix, Debezium applies the regular expression that you specify as an anchored regular expression. That is, the specified expression is matched against the entire message prefix string; the expression does not match substrings that might be present in a prefix.\n\nIf you include this property in the configuration, do not also set the `messagePrefixExcludeList` property.\n\nFor information about the structure of message events and about their ordering semantics, see [message events](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-message-events).\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "moneyFractionDigits" = mkOption {
          description = "Default `2`. Specifies how many decimal digits should be used when converting Postgres money type to java.math.BigDecimal, which represents the values in change events. Applicable only when decimalHandlingMode is set to precise.\n";
          type = (types.nullOr types.int);
        };
        "notificationEnabledChannels" = mkOption {
          description = "List of notification channel names that are enabled for the connector. By default, the following channels are available: sink, log and jmx. Optionally, you can also implement a [custom notification channel](https://debezium.io/documentation/reference/stable/configuration/signalling.html#debezium-signaling-enabling-custom-signaling-channel).\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "pluginName" = mkOption {
          description = "Default `pgoutput`. The name of the [PostgreSQL logical decoding plug-in](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-output-plugin) installed on the PostgreSQL server. Supported values are decoderbufs, and pgoutput.\n";
          type = (types.nullOr types.str);
        };
        "pollIntervalMs" = mkOption {
          description = "Default `500`. Positive integer value that specifies the number of milliseconds the connector should wait for new change events to appear before it starts processing a batch of events. Defaults to 500 milliseconds.\n";
          type = (types.nullOr types.int);
        };
        "provideTransactionMetadata" = mkOption {
          description = "Default `false`. Determines whether the connector generates events with transaction boundaries and enriches change event envelopes with transaction metadata. Specify true if you want the connector to do this. For more information, see [Transaction metadata](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-transaction-metadata).\n";
          type = (types.nullOr types.bool);
        };
        "publicationAutocreateMode" = mkOption {
          description = "Default `all_tables`. Applies only when streaming changes by using [the pgoutput plug-in](https://www.postgresql.org/docs/current/sql-createpublication.html). The setting determines how creation of a [publication](https://www.postgresql.org/docs/current/logical-replication-publication.html) should work. Specify one of the following values:\n\n* `all_tables` - If a publication exists, the connector uses it. If a publication does not exist, the connector creates a publication for all tables in the database for which the connector is capturing changes. For the connector to create a publication it must access the database through a database user account that has permission to create publications and perform replications. You grant the required permission by using the following SQL command CREATE PUBLICATION <publication_name> FOR ALL TABLES;.\n* `disabled` - The connector does not attempt to create a publication. A database administrator or the user configured to perform replications must have created the publication before running the connector. If the connector cannot find the publication, the connector throws an exception and stops.\n* `filtered` - If a publication exists, the connector uses it. If no publication exists, the connector creates a new publication for tables that match the current filter configuration as specified by the schema.include.list, schema.exclude.list, and table.include.list, and table.exclude.list connector configuration properties. For example: CREATE PUBLICATION <publication_name> FOR TABLE <tbl1, tbl2, tbl3>. If the publication exists, the connector updates the publication for tables that match the current filter configuration. For example: ALTER PUBLICATION <publication_name> SET TABLE <tbl1, tbl2, tbl3>.\n";
          type = (types.nullOr types.str);
        };
        "publicationName" = mkOption {
          description = "Default <SGStream name>.<SGStream namespace> (with all characters that are not `[a-zA-Z0-9]` changed to `_` character). The name of the PostgreSQL publication created for streaming changes when using pgoutput. This publication is created at start-up if it does not already exist and it includes all tables. Debezium then applies its own include/exclude list filtering, if configured, to limit the publication to change events for the specific tables of interest. The connector user must have superuser permissions to create this publication, so it is usually preferable to create the publication before starting the connector for the first time. If the publication already exists, either for all tables or configured with a subset of tables, Debezium uses the publication as it is defined.\n";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "Default `false`. Specifies whether a connector writes watermarks to the signal data collection to track the progress of an incremental snapshot. Set the value to `true` to enable a connector that has a read-only connection to the database to use an incremental snapshot watermarking strategy that does not require writing to the signal data collection.\n";
          type = (types.nullOr types.bool);
        };
        "replicaIdentityAutosetValues" = mkOption {
          description = "The setting determines the value for [replica identity](https://www.postgresql.org/docs/current/sql-altertable.html#SQL-ALTERTABLE-REPLICA-IDENTITY) at table level.\n  This option will overwrite the existing value in database. A comma-separated list of regular expressions that match fully-qualified tables and replica identity value to be used in the table.\n  Each expression must match the pattern '<fully-qualified table name>:<replica identity>', where the table name could be defined as (SCHEMA_NAME.TABLE_NAME), and the replica identity values are:\n  DEFAULT - Records the old values of the columns of the primary key, if any. This is the default for non-system tables.\n  INDEX index_name - Records the old values of the columns covered by the named index, that must be unique, not partial, not deferrable, and include only columns marked NOT NULL. If this index is dropped, the behavior is the same as NOTHING.\n  FULL - Records the old values of all columns in the row.\n  NOTHING - Records no information about the old row. This is the default for system tables.\n  For example,\n  schema1.*:FULL,schema2.table2:NOTHING,schema2.table3:INDEX idx_name\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "retriableRestartConnectorWaitMs" = mkOption {
          description = "Default `10000` (10 seconds). The number of milliseconds to wait before restarting a connector after a retriable error occurs.\n";
          type = (types.nullOr types.int);
        };
        "schemaNameAdjustmentMode" = mkOption {
          description = "Default `none`. Specifies how schema names should be adjusted for compatibility with the message converter used by the connector. Possible settings:\n\n* `none` does not apply any adjustment.\n* `avro` replaces the characters that cannot be used in the Avro type name with underscore.\n* `avro_unicode` replaces the underscore or characters that cannot be used in the Avro type name with corresponding unicode like _uxxxx. Note: _ is an escape sequence like backslash in Java\n";
          type = (types.nullOr types.str);
        };
        "schemaRefreshMode" = mkOption {
          description = "Default `columns_diff`. Specify the conditions that trigger a refresh of the in-memory schema for a table.\n\n* `columns_diff`: is the safest mode. It ensures that the in-memory schema stays in sync with the database table’s schema at all times.\n* `columns_diff_exclude_unchanged_toast`: instructs the connector to refresh the in-memory schema cache if there is a discrepancy with the schema derived from the incoming message, unless unchanged TOASTable data fully accounts for the discrepancy.\n\nThis setting can significantly improve connector performance if there are frequently-updated tables that have TOASTed data that are rarely part of updates. However, it is possible for the in-memory schema to become outdated if TOASTable columns are dropped from the table.\n";
          type = (types.nullOr types.str);
        };
        "signalDataCollection" = mkOption {
          description = "Fully-qualified name of the data collection that is used to send signals to the connector. Use the following format to specify the collection name: <schemaName>.<tableName>\n";
          type = (types.nullOr types.str);
        };
        "signalEnabledChannels" = mkOption {
          description = "Default `[sgstream-annotations]`. List of the signaling channel names that are enabled for the connector. By default, the following channels are available: sgstream-annotations, source, kafka, file and jmx. Optionally, you can also implement a [custom signaling channel](https://debezium.io/documentation/reference/stable/configuration/signalling.html#debezium-signaling-enabling-custom-signaling-channel).\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "skipMessagesWithoutChange" = mkOption {
          description = "Default `false`. Specifies whether to skip publishing messages when there is no change in included columns. This would essentially filter messages if there is no change in columns included as per includes or excludes fields. Note: Only works when REPLICA IDENTITY of the table is set to FULL\n";
          type = (types.nullOr types.bool);
        };
        "skippedOperations" = mkOption {
          description = "Default `none`. A list of operation types that will be skipped during streaming. The operations include: c for inserts/create, u for updates, d for deletes, t for truncates, and none to not skip any operations. By default, no operations are skipped.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "slotDropOnStop" = mkOption {
          description = "Default `true`. Whether or not to delete the logical replication slot when the connector stops in a graceful, expected way. The default behavior is that the replication slot remains configured for the connector when the connector stops. When the connector restarts, having the same replication slot enables the connector to start processing where it left off. Set to true in only testing or development environments. Dropping the slot allows the database to discard WAL segments. When the connector restarts it performs a new snapshot or it can continue from a persistent offset in the target offsets topic.\n";
          type = (types.nullOr types.bool);
        };
        "slotFailover" = mkOption {
          description = "Default `false'. Specifies whether the connector creates a failover slot. If you omit this setting, or if the primary server runs PostgreSQL 16 or earlier, the connector does not create a failover slot.\n\nPostgreSQL uses the `synchronized_standby_slots` parameter to configure replication slot synchronization between primary and standby servers. Set this parameter on the primary server to specify the physical replication slots that it synchronizes with on standby servers. \n";
          type = (types.nullOr types.bool);
        };
        "slotMaxRetries" = mkOption {
          description = "Default `6`. If connecting to a replication slot fails, this is the maximum number of consecutive attempts to connect.\n";
          type = (types.nullOr types.int);
        };
        "slotName" = mkOption {
          description = "Default <SGStream namespace>.<SGStream name> (with all characters that are not `[a-zA-Z0-9]` changed to `_` character). The name of the PostgreSQL logical decoding slot that was created for streaming changes from a particular plug-in for a particular database/schema. The server uses this slot to stream events to the Debezium connector that you are configuring.\n\nSlot names must conform to [PostgreSQL replication slot naming rules](https://www.postgresql.org/docs/current/static/warm-standby.html#STREAMING-REPLICATION-SLOTS-MANIPULATION), which state: \"Each replication slot has a name, which can contain lower-case letters, numbers, and the underscore character.\"\n";
          type = (types.nullOr types.str);
        };
        "slotRetryDelayMs" = mkOption {
          description = "Default `10000` (10 seconds). The number of milliseconds to wait between retry attempts when the connector fails to connect to a replication slot.\n";
          type = (types.nullOr types.int);
        };
        "slotStreamParams" = mkOption {
          description = "Parameters to pass to the configured logical decoding plug-in. For example:\n\n```\nslotStreamParams:\n  add-tables: \"public.table,public.table2\"\n  include-lsn: \"true\"\n```\n";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "snapshotDelayMs" = mkOption {
          description = "An interval in milliseconds that the connector should wait before performing a snapshot when the connector starts. If you are starting multiple connectors in a cluster, this property is useful for avoiding snapshot interruptions, which might cause re-balancing of connectors.\n";
          type = (types.nullOr types.int);
        };
        "snapshotFetchSize" = mkOption {
          description = "Default `10240`. During a snapshot, the connector reads table content in batches of rows. This property specifies the maximum number of rows in a batch.\n";
          type = (types.nullOr types.int);
        };
        "snapshotIncludeCollectionList" = mkOption {
          description = "Default <All tables / All tables filtered in `includes` field / All tables that are not filtered out in `excludes` field>. An optional, list of regular expressions that match the fully-qualified names (<schemaName>.<tableName>) of the tables to include in a snapshot. The specified items must be named in the connector’s table.include.list property. This property takes effect only if the connector’s snapshotMode property is set to a value other than `never`. This property does not affect the behavior of incremental snapshots.\n   To match the name of a table, Debezium applies the regular expression that you specify as an anchored regular expression. That is, the specified expression is matched against the entire name string of the table; it does not match substrings that might be present in a table name.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "snapshotIsolationMode" = mkOption {
          description = "Default `serializable`. Specifies the transaction isolation level and the type of locking, if any, that the connector applies when it reads data during an initial snapshot or ad hoc blocking snapshot.\n\nEach isolation level strikes a different balance between optimizing concurrency and performance on the one hand, and maximizing data consistency and accuracy on the other. Snapshots that use stricter isolation levels result in higher quality, more consistent data, but the cost of the improvement is decreased performance due to longer lock times and fewer concurrent transactions. Less restrictive isolation levels can increase efficiency, but at the expense of inconsistent data. For more information about transaction isolation levels in PostgreSQL, see the [PostgreSQL documentation](https://www.postgresql.org/docs/current/transaction-iso.html).\n\nSpecify one of the following isolation levels:\n\n* `serializable`: The default, and most restrictive isolation level. This option prevents serialization anomalies and provides the highest degree of data integrity. To ensure the data consistency of captured tables, a snapshot runs in a transaction that uses a repeatable read isolation level, blocking concurrent DDL changes on the tables, and locking the database to index creation. When this option is set, users or administrators cannot perform certain operations, such as creating a table index, until the snapshot concludes. The entire range of table keys remains locked until the snapshot completes. This option matches the snapshot behavior that was available in the connector before the introduction of this property.\n* `repeatable_read`: Prevents other transactions from updating table rows during the snapshot. New records captured by the snapshot can appear twice; first, as part of the initial snapshot, and then again in the streaming phase. However, this level of consistency is tolerable for database mirroring. Ensures data consistency between the tables being scanned and blocking DDL on the selected tables, and concurrent index creation throughout the database. Allows for serialization anomalies.\n* `read_committed`: In PostgreSQL, there is no difference between the behavior of the Read Uncommitted and Read Committed isolation modes. As a result, for this property, the read_committed option effectively provides the least restrictive level of isolation. Setting this option sacrifices some consistency for initial and ad hoc blocking snapshots, but provides better database performance for other users during the snapshot. In general, this transaction consistency level is appropriate for data mirroring. Other transactions cannot update table rows during the snapshot. However, minor data inconsistencies can occur when a record is added during the initial snapshot, and the connector later recaptures the record after the streaming phase begins.\n* `read_uncommitted`: Nominally, this option offers the least restrictive level of isolation. However, as explained in the description for the read-committed option, for the Debezium PostgreSQL connector, this option provides the same level of isolation as the read_committed option.\n";
          type = (types.nullOr types.str);
        };
        "snapshotLockTimeoutMs" = mkOption {
          description = "Default `10000`. Positive integer value that specifies the maximum amount of time (in milliseconds) to wait to obtain table locks when performing a snapshot. If the connector cannot acquire table locks in this time interval, the snapshot fails. [How the connector performs snapshots](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-snapshots) provides details.\n";
          type = (types.nullOr types.int);
        };
        "snapshotLockingMode" = mkOption {
          description = "Default `none`. Specifies how the connector holds locks on tables while performing a schema snapshot. Set one of the following options:\n\n* `shared`: The connector holds a table lock that prevents exclusive table access during the initial portion phase of the snapshot in which database schemas and other metadata are read. After the initial phase, the snapshot no longer requires table locks.\n* `none`: The connector avoids locks entirely. Do not use this mode if schema changes might occur during the snapshot.\n\n> *WARNING*: Do not use this mode if schema changes might occur during the snapshot.\n\n* `custom`: The connector performs a snapshot according to the implementation specified by the snapshotLockingModeCustomName property, which is a custom implementation of the io.debezium.spi.snapshot.SnapshotLock interface.\n";
          type = (types.nullOr types.str);
        };
        "snapshotLockingModeCustomName" = mkOption {
          description = "When snapshotLockingMode is set to custom, use this setting to specify the name of the custom implementation provided in the name() method that is defined by the 'io.debezium.spi.snapshot.SnapshotLock' interface. For more information, see [custom snapshotter SPI](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#connector-custom-snapshot).\n";
          type = (types.nullOr types.str);
        };
        "snapshotMaxThreads" = mkOption {
          description = "Default `1`. Specifies the number of threads that the connector uses when performing an initial snapshot. To enable parallel initial snapshots, set the property to a value greater than 1. In a parallel initial snapshot, the connector processes multiple tables concurrently. This feature is incubating.\n";
          type = (types.nullOr types.int);
        };
        "snapshotMode" = mkOption {
          description = "Default `initial`. Specifies the criteria for performing a snapshot when the connector starts:\n\n* `always` - The connector performs a snapshot every time that it starts. The snapshot includes the structure and data of the captured tables. Specify this value to populate topics with a complete representation of the data from the captured tables every time that the connector starts. After the snapshot completes, the connector begins to stream event records for subsequent database changes.\n* `initial` - The connector performs a snapshot only when no offsets have been recorded for the logical server name.\n* `initial_only` - The connector performs an initial snapshot and then stops, without processing any subsequent changes.\n* `no_data` - The connector never performs snapshots. When a connector is configured this way, after it starts, it behaves as follows: If there is a previously stored LSN in the offsets topic, the connector continues streaming changes from that position. If no LSN is stored, the connector starts streaming changes from the point in time when the PostgreSQL logical replication slot was created on the server. Use this snapshot mode only when you know all data of interest is still reflected in the WAL.\n* `never` - Deprecated see no_data.\n* `when_needed` - After the connector starts, it performs a snapshot only if it detects one of the following circumstances: \n  It cannot detect any topic offsets.\n  A previously recorded offset specifies a log position that is not available on the server.\n* `configuration_based` - With this option, you control snapshot behavior through a set of connector properties that have the prefix 'snapshotModeConfigurationBased'.\n* `custom` - The connector performs a snapshot according to the implementation specified by the snapshotModeCustomName property, which defines a custom implementation of the io.debezium.spi.snapshot.Snapshotter interface.\n\nFor more information, see the [table of snapshot.mode options](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-connector-snapshot-mode-options).\n";
          type = (types.nullOr types.str);
        };
        "snapshotModeConfigurationBasedSnapshotData" = mkOption {
          description = "Default `false`. If the snapshotMode is set to configuration_based, set this property to specify whether the connector includes table data when it performs a snapshot.\n";
          type = (types.nullOr types.bool);
        };
        "snapshotModeConfigurationBasedSnapshotOnDataError" = mkOption {
          description = "Default `false`. If the snapshotMode is set to configuration_based, this property specifies whether the connector attempts to snapshot table data if it does not find the last committed offset in the transaction log. Set the value to true to instruct the connector to perform a new snapshot.\n";
          type = (types.nullOr types.bool);
        };
        "snapshotModeConfigurationBasedSnapshotOnSchemaError" = mkOption {
          description = "Default `false`. If the snapshotMode is set to configuration_based, set this property to specify whether the connector includes table schema in a snapshot if the schema history topic is not available.\n";
          type = (types.nullOr types.bool);
        };
        "snapshotModeConfigurationBasedSnapshotSchema" = mkOption {
          description = "Default `false`. If the snapshotMode is set to configuration_based, set this property to specify whether the connector includes the table schema when it performs a snapshot.\n";
          type = (types.nullOr types.bool);
        };
        "snapshotModeConfigurationBasedStartStream" = mkOption {
          description = "Default `false`. If the snapshotMode is set to configuration_based, set this property to specify whether the connector begins to stream change events after a snapshot completes.\n";
          type = (types.nullOr types.bool);
        };
        "snapshotModeCustomName" = mkOption {
          description = "When snapshotMode is set as custom, use this setting to specify the name of the custom implementation provided in the name() method that is defined by the 'io.debezium.spi.snapshot.Snapshotter' interface. The provided implementation is called after a connector restart to determine whether to perform a snapshot. For more information, see [custom snapshotter SPI](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#connector-custom-snapshot).\n";
          type = (types.nullOr types.str);
        };
        "snapshotQueryMode" = mkOption {
          description = "Default `select_all`. Specifies how the connector queries data while performing a snapshot. Set one of the following options:\n\n* `select_all`: The connector performs a select all query by default, optionally adjusting the columns selected based on the column include and exclude list configurations.\n* `custom`: The connector performs a snapshot query according to the implementation specified by the snapshotQueryModeCustomName property, which defines a custom implementation of the io.debezium.spi.snapshot.SnapshotQuery interface. This setting enables you to manage snapshot content in a more flexible manner compared to using the snapshotSelectStatementOverrides property.\n";
          type = (types.nullOr types.str);
        };
        "snapshotQueryModeCustomName" = mkOption {
          description = "When snapshotQueryMode is set as custom, use this setting to specify the name of the custom implementation provided in the name() method that is defined by the 'io.debezium.spi.snapshot.SnapshotQuery' interface. For more information, see [custom snapshotter SPI](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#connector-custom-snapshot).\n";
          type = (types.nullOr types.str);
        };
        "snapshotSelectStatementOverrides" = mkOption {
          description = "Specifies the table rows to include in a snapshot. Use the property if you want a snapshot to include only a subset of the rows in a table. This property affects snapshots only. It does not apply to events that the connector reads from the log.\n The property contains a hierarchy of fully-qualified table names in the form <schemaName>.<tableName>. For example,\n\n```\nsnapshotSelectStatementOverrides: \n  \"customers.orders\": \"SELECT * FROM [customers].[orders] WHERE delete_flag = 0 ORDER BY id DESC\"\n```\n\nIn the resulting snapshot, the connector includes only the records for which delete_flag = 0.\n";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "statusUpdateIntervalMs" = mkOption {
          description = "Default `10000`. Frequency for sending replication connection status updates to the server, given in milliseconds. The property also controls how frequently the database status is checked to detect a dead connection in case the database was shut down.\n";
          type = (types.nullOr types.int);
        };
        "timePrecisionMode" = mkOption {
          description = "Default `adaptive`. Time, date, and timestamps can be represented with different kinds of precision:\n\n* `adaptive`: captures the time and timestamp values exactly as in the database using either millisecond, microsecond, or nanosecond precision values based on the database column’s type.\n* `adaptive_time_microseconds`: captures the date, datetime and timestamp values exactly as in the database using either millisecond, microsecond, or nanosecond precision values based on the database column’s type. An exception is TIME type fields, which are always captured as microseconds.\n* `connect`: always represents time and timestamp values by using Kafka Connect’s built-in representations for Time, Date, and Timestamp, which use millisecond precision regardless of the database columns' precision. For more information, see [temporal values](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-temporal-types).\n";
          type = (types.nullOr types.str);
        };
        "tombstonesOnDelete" = mkOption {
          description = "Default `true`. Controls whether a delete event is followed by a tombstone event.\n\n* `true` - a delete operation is represented by a delete event and a subsequent tombstone event.\n* `false` - only a delete event is emitted.\n\nAfter a source record is deleted, emitting a tombstone event (the default behavior) allows to completely delete all events that pertain to the key of the deleted row in case [log compaction](https://kafka.apache.org/documentation/#compaction) is enabled for the topic.\n";
          type = (types.nullOr types.bool);
        };
        "topicCacheSize" = mkOption {
          description = "Default `10000`. The size used for holding the topic names in bounded concurrent hash map. This cache will help to determine the topic name corresponding to a given data collection.\n";
          type = (types.nullOr types.int);
        };
        "topicDelimiter" = mkOption {
          description = "Default `.`. Specify the delimiter for topic name, defaults to \".\".\n";
          type = (types.nullOr types.str);
        };
        "topicHeartbeatPrefix" = mkOption {
          description = "Default `__debezium-heartbeat`. Controls the name of the topic to which the connector sends heartbeat messages. For example, if the topic prefix is fulfillment, the default topic name is __debezium-heartbeat.fulfillment.\n";
          type = (types.nullOr types.str);
        };
        "topicNamingStrategy" = mkOption {
          description = "Default `io.debezium.schema.SchemaTopicNamingStrategy`. The name of the TopicNamingStrategy class that should be used to determine the topic name for data change, schema change, transaction, heartbeat event etc., defaults to SchemaTopicNamingStrategy.\n";
          type = (types.nullOr types.str);
        };
        "topicTransaction" = mkOption {
          description = "Default `transaction`. Controls the name of the topic to which the connector sends transaction metadata messages. For example, if the topic prefix is fulfillment, the default topic name is fulfillment.transaction.\n";
          type = (types.nullOr types.str);
        };
        "unavailableValuePlaceholder" = mkOption {
          description = "Default `__debezium_unavailable_value`. Specifies the constant that the connector provides to indicate that the original value is a toasted value that is not provided by the database. If the setting of unavailable.value.placeholder starts with the hex: prefix it is expected that the rest of the string represents hexadecimally encoded octets. For more information, see [toasted values](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-toasted-values).\n";
          type = (types.nullOr types.str);
        };
        "xminFetchIntervalMs" = mkOption {
          description = "Default `0`. How often, in milliseconds, the XMIN will be read from the replication slot. The XMIN value provides the lower bounds of where a new replication slot could start from. The default value of 0 disables tracking XMIN tracking.\n";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "binaryHandlingMode" = mkOverride 1002 null;
        "columnMaskHash" = mkOverride 1002 null;
        "columnMaskHashV2" = mkOverride 1002 null;
        "columnMaskWithLengthChars" = mkOverride 1002 null;
        "columnPropagateSourceType" = mkOverride 1002 null;
        "columnTruncateToLengthChars" = mkOverride 1002 null;
        "converters" = mkOverride 1002 null;
        "customMetricTags" = mkOverride 1002 null;
        "databaseInitialStatements" = mkOverride 1002 null;
        "databaseQueryTimeoutMs" = mkOverride 1002 null;
        "datatypePropagateSourceType" = mkOverride 1002 null;
        "decimalHandlingMode" = mkOverride 1002 null;
        "errorsMaxRetries" = mkOverride 1002 null;
        "eventProcessingFailureHandlingMode" = mkOverride 1002 null;
        "fieldNameAdjustmentMode" = mkOverride 1002 null;
        "flushLsnSource" = mkOverride 1002 null;
        "heartbeatActionQuery" = mkOverride 1002 null;
        "heartbeatIntervalMs" = mkOverride 1002 null;
        "hstoreHandlingMode" = mkOverride 1002 null;
        "includeUnknownDatatypes" = mkOverride 1002 null;
        "incrementalSnapshotChunkSize" = mkOverride 1002 null;
        "incrementalSnapshotWatermarkingStrategy" = mkOverride 1002 null;
        "intervalHandlingMode" = mkOverride 1002 null;
        "maxBatchSize" = mkOverride 1002 null;
        "maxQueueSize" = mkOverride 1002 null;
        "maxQueueSizeInBytes" = mkOverride 1002 null;
        "messageKeyColumns" = mkOverride 1002 null;
        "messagePrefixExcludeList" = mkOverride 1002 null;
        "messagePrefixIncludeList" = mkOverride 1002 null;
        "moneyFractionDigits" = mkOverride 1002 null;
        "notificationEnabledChannels" = mkOverride 1002 null;
        "pluginName" = mkOverride 1002 null;
        "pollIntervalMs" = mkOverride 1002 null;
        "provideTransactionMetadata" = mkOverride 1002 null;
        "publicationAutocreateMode" = mkOverride 1002 null;
        "publicationName" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "replicaIdentityAutosetValues" = mkOverride 1002 null;
        "retriableRestartConnectorWaitMs" = mkOverride 1002 null;
        "schemaNameAdjustmentMode" = mkOverride 1002 null;
        "schemaRefreshMode" = mkOverride 1002 null;
        "signalDataCollection" = mkOverride 1002 null;
        "signalEnabledChannels" = mkOverride 1002 null;
        "skipMessagesWithoutChange" = mkOverride 1002 null;
        "skippedOperations" = mkOverride 1002 null;
        "slotDropOnStop" = mkOverride 1002 null;
        "slotFailover" = mkOverride 1002 null;
        "slotMaxRetries" = mkOverride 1002 null;
        "slotName" = mkOverride 1002 null;
        "slotRetryDelayMs" = mkOverride 1002 null;
        "slotStreamParams" = mkOverride 1002 null;
        "snapshotDelayMs" = mkOverride 1002 null;
        "snapshotFetchSize" = mkOverride 1002 null;
        "snapshotIncludeCollectionList" = mkOverride 1002 null;
        "snapshotIsolationMode" = mkOverride 1002 null;
        "snapshotLockTimeoutMs" = mkOverride 1002 null;
        "snapshotLockingMode" = mkOverride 1002 null;
        "snapshotLockingModeCustomName" = mkOverride 1002 null;
        "snapshotMaxThreads" = mkOverride 1002 null;
        "snapshotMode" = mkOverride 1002 null;
        "snapshotModeConfigurationBasedSnapshotData" = mkOverride 1002 null;
        "snapshotModeConfigurationBasedSnapshotOnDataError" = mkOverride 1002 null;
        "snapshotModeConfigurationBasedSnapshotOnSchemaError" = mkOverride 1002 null;
        "snapshotModeConfigurationBasedSnapshotSchema" = mkOverride 1002 null;
        "snapshotModeConfigurationBasedStartStream" = mkOverride 1002 null;
        "snapshotModeCustomName" = mkOverride 1002 null;
        "snapshotQueryMode" = mkOverride 1002 null;
        "snapshotQueryModeCustomName" = mkOverride 1002 null;
        "snapshotSelectStatementOverrides" = mkOverride 1002 null;
        "statusUpdateIntervalMs" = mkOverride 1002 null;
        "timePrecisionMode" = mkOverride 1002 null;
        "tombstonesOnDelete" = mkOverride 1002 null;
        "topicCacheSize" = mkOverride 1002 null;
        "topicDelimiter" = mkOverride 1002 null;
        "topicHeartbeatPrefix" = mkOverride 1002 null;
        "topicNamingStrategy" = mkOverride 1002 null;
        "topicTransaction" = mkOverride 1002 null;
        "unavailableValuePlaceholder" = mkOverride 1002 null;
        "xminFetchIntervalMs" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecSourceSgClusterPassword" = {

      options = {
        "key" = mkOption {
          description = "The Secret key where the password is stored.\n";
          type = types.str;
        };
        "name" = mkOption {
          description = "The Secret name where the password is stored.\n";
          type = types.str;
        };
      };

      config = { };

    };
    "stackgres.io.v1alpha1.SGStreamSpecSourceSgClusterUsername" = {

      options = {
        "key" = mkOption {
          description = "The Secret key where the username is stored.\n";
          type = types.str;
        };
        "name" = mkOption {
          description = "The Secret name where the username is stored.\n";
          type = types.str;
        };
      };

      config = { };

    };
    "stackgres.io.v1alpha1.SGStreamSpecTarget" = {

      options = {
        "cloudEvent" = mkOption {
          description = "Configuration section for `CloudEvent` target type.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecTargetCloudEvent"));
        };
        "pgLambda" = mkOption {
          description = "Configuration section for `PgLambda` target type.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecTargetPgLambda"));
        };
        "sgCluster" = mkOption {
          description = "The configuration of the data target required when type is `SGCluster`.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecTargetSgCluster"));
        };
        "type" = mkOption {
          description = "Indicate the type of target of this stream. Possible values are:\n\n* `CloudEvent`: events will be sent to a cloud event receiver.\n* `PgLambda`: events will trigger the execution of a lambda script by integrating with [Knative Service](https://knative.dev/docs/serving/) (Knative must be already installed).\n* `SGCluster`: events will be sinked to an SGCluster allowing migration of data.\n";
          type = types.str;
        };
      };

      config = {
        "cloudEvent" = mkOverride 1002 null;
        "pgLambda" = mkOverride 1002 null;
        "sgCluster" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecTargetCloudEvent" = {

      options = {
        "binding" = mkOption {
          description = "The CloudEvent binding (http by default).\n\nOnly http is supported at the moment.\n";
          type = (types.nullOr types.str);
        };
        "format" = mkOption {
          description = "The CloudEvent format (json by default).\n\nOnly json is supported at the moment.\n";
          type = (types.nullOr types.str);
        };
        "http" = mkOption {
          description = "The http binding configuration.";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecTargetCloudEventHttp"));
        };
      };

      config = {
        "binding" = mkOverride 1002 null;
        "format" = mkOverride 1002 null;
        "http" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecTargetCloudEventHttp" = {

      options = {
        "connectTimeout" = mkOption {
          description = "Set the connect timeout.\n\nValue 0 represents infinity (default). Negative values are not allowed.\n";
          type = (types.nullOr types.str);
        };
        "headers" = mkOption {
          description = "Headers to include when sending CloudEvents to the endpoint.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "readTimeout" = mkOption {
          description = "Set the read timeout. The value is the timeout to read a response.\n\nValue 0 represents infinity (default). Negative values are not allowed.\n";
          type = (types.nullOr types.str);
        };
        "retryBackoffDelay" = mkOption {
          description = "The maximum amount of delay in seconds after an error before retrying again.\n\nThe initial delay will use 10% of this value and then increase the value exponentially up to the maximum amount of seconds specified with this field.\n";
          type = (types.nullOr types.int);
        };
        "retryLimit" = mkOption {
          description = "Set the retry limit. When set the event will be sent again after an error for the specified limit of times. When not set the event will be sent again after an error.\n";
          type = (types.nullOr types.int);
        };
        "skipHostnameVerification" = mkOption {
          description = "When `true` disable hostname verification.";
          type = (types.nullOr types.bool);
        };
        "url" = mkOption {
          description = "The URL used to send the CloudEvents to the endpoint.";
          type = types.str;
        };
      };

      config = {
        "connectTimeout" = mkOverride 1002 null;
        "headers" = mkOverride 1002 null;
        "readTimeout" = mkOverride 1002 null;
        "retryBackoffDelay" = mkOverride 1002 null;
        "retryLimit" = mkOverride 1002 null;
        "skipHostnameVerification" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecTargetPgLambda" = {

      options = {
        "knative" = mkOption {
          description = "Knative Service configuration.";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecTargetPgLambdaKnative"));
        };
        "script" = mkOption {
          description = "Script to execute. This field is mutually exclusive with `scriptFrom` field.\n";
          type = (types.nullOr types.str);
        };
        "scriptFrom" = mkOption {
          description = "Reference to either a Kubernetes [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) or a [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) that contains the script to execute. This field is mutually exclusive with `script` field.\n\nFields `secretKeyRef` and `configMapKeyRef` are mutually exclusive, and one of them is required.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecTargetPgLambdaScriptFrom"));
        };
        "scriptType" = mkOption {
          description = "The PgLambda script format (javascript by default).\n\n* `javascript`: the script will receive the following variable:\n  * `request`: the HTTP request object. See https://nodejs.org/docs/latest-v18.x/api/http.html#class-httpclientrequest\n  * `response`: the HTTP response object. See https://nodejs.org/docs/latest-v18.x/api/http.html#class-httpserverresponse\n  * `event`: the CloudEvent event object. See https://github.com/cloudevents/sdk-javascript\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "knative" = mkOverride 1002 null;
        "script" = mkOverride 1002 null;
        "scriptFrom" = mkOverride 1002 null;
        "scriptType" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecTargetPgLambdaKnative" = {

      options = {
        "annotations" = mkOption {
          description = "Annotations to set to Knative Service";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "http" = mkOption {
          description = "PgLambda uses a CloudEvent http binding to send events to the Knative Service. This section allow to modify the configuration of this binding.";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecTargetPgLambdaKnativeHttp"));
        };
        "labels" = mkOption {
          description = "Labels to set to Knative Service";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "http" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecTargetPgLambdaKnativeHttp" = {

      options = {
        "connectTimeout" = mkOption {
          description = "Set the connect timeout.\n\nValue 0 represents infinity (default). Negative values are not allowed.\n";
          type = (types.nullOr types.str);
        };
        "headers" = mkOption {
          description = "Headers to include when sending CloudEvents to the endpoint.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "readTimeout" = mkOption {
          description = "Set the read timeout. The value is the timeout to read a response.\n\nValue 0 represents infinity (default). Negative values are not allowed.\n";
          type = (types.nullOr types.str);
        };
        "retryBackoffDelay" = mkOption {
          description = "The maximum amount of delay in seconds after an error before retrying again.\n\nThe initial delay will use 10% of this value and then increase the value exponentially up to the maximum amount of seconds specified with this field.\n";
          type = (types.nullOr types.int);
        };
        "retryLimit" = mkOption {
          description = "Set the retry limit. When set the event will be sent again after an error for the specified limit of times. When not set the event will be sent again after an error.\n";
          type = (types.nullOr types.int);
        };
        "skipHostnameVerification" = mkOption {
          description = "When `true` disable hostname verification.";
          type = (types.nullOr types.bool);
        };
        "url" = mkOption {
          description = "The URL used to send the CloudEvents to the endpoint.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "connectTimeout" = mkOverride 1002 null;
        "headers" = mkOverride 1002 null;
        "readTimeout" = mkOverride 1002 null;
        "retryBackoffDelay" = mkOverride 1002 null;
        "retryLimit" = mkOverride 1002 null;
        "skipHostnameVerification" = mkOverride 1002 null;
        "url" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecTargetPgLambdaScriptFrom" = {

      options = {
        "configMapKeyRef" = mkOption {
          description = "A [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) reference that contains the script to execute. This field is mutually exclusive with `secretKeyRef` field.\n";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1alpha1.SGStreamSpecTargetPgLambdaScriptFromConfigMapKeyRef"
            )
          );
        };
        "secretKeyRef" = mkOption {
          description = "A Kubernetes [SecretKeySelector](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#secretkeyselector-v1-core) that contains the script to execute. This field is mutually exclusive with `configMapKeyRef` field.\n";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecTargetPgLambdaScriptFromSecretKeyRef")
          );
        };
      };

      config = {
        "configMapKeyRef" = mkOverride 1002 null;
        "secretKeyRef" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecTargetPgLambdaScriptFromConfigMapKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key name within the ConfigMap that contains the script to execute.\n";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the ConfigMap that contains the script to execute.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecTargetPgLambdaScriptFromSecretKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from. Must be a valid secret key.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecTargetSgCluster" = {

      options = {
        "database" = mkOption {
          description = "The target database name to which the data will be migrated to.\n\nIf not specified the default postgres database will be targeted.\n";
          type = (types.nullOr types.str);
        };
        "ddlImportRoleSkipFilter" = mkOption {
          description = "Allow to set a [SIMILAR TO regular expression](https://www.postgresql.org/docs/current/functions-matching.html#FUNCTIONS-SIMILARTO-REGEXP) to match the names of the roles to skip during import of DDL.\n\nWhen not set and source is an SGCluster will match the superuser, replicator and authenticator usernames.\n";
          type = (types.nullOr types.str);
        };
        "debeziumProperties" = mkOption {
          description = "Specific property of the debezium JDBC sink.\n\nSee https://debezium.io/documentation/reference/stable/connectors/jdbc.html#jdbc-connector-configuration\n\nEach property is converted from myPropertyName to my.property.name\n";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecTargetSgClusterDebeziumProperties")
          );
        };
        "name" = mkOption {
          description = "The target SGCluster name.\n";
          type = types.str;
        };
        "password" = mkOption {
          description = "The password used by the CDC sink process to connect to the database.\n\nIf not specified the default superuser password will be used.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecTargetSgClusterPassword"));
        };
        "skipDdlImport" = mkOption {
          description = "When `true` disable import of DDL and tables will be created on demand by Debezium.\n";
          type = (types.nullOr types.bool);
        };
        "skipDropIndexesAndConstraints" = mkOption {
          description = "When `true` disable drop of indexes and constraints that improve snapshotting performance.\n";
          type = (types.nullOr types.bool);
        };
        "skipRestoreIndexesAfterSnapshot" = mkOption {
          description = "When `true` disable restore of indexes on the first non-snapshot event. This option is required when using incremental snapshotting. This option is ignored when `skipDropIndexesAndConstraints` is set to `true`.\n";
          type = (types.nullOr types.bool);
        };
        "username" = mkOption {
          description = "The username used by the CDC sink process to connect to the database.\n\nIf not specified the default superuser username (by default postgres) will be used.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamSpecTargetSgClusterUsername"));
        };
      };

      config = {
        "database" = mkOverride 1002 null;
        "ddlImportRoleSkipFilter" = mkOverride 1002 null;
        "debeziumProperties" = mkOverride 1002 null;
        "password" = mkOverride 1002 null;
        "skipDdlImport" = mkOverride 1002 null;
        "skipDropIndexesAndConstraints" = mkOverride 1002 null;
        "skipRestoreIndexesAfterSnapshot" = mkOverride 1002 null;
        "username" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecTargetSgClusterDebeziumProperties" = {

      options = {
        "batchSize" = mkOption {
          description = "Default `500`. Specifies how many records to attempt to batch together into the destination table.\n> Note that if you set `consumerMaxPollRecords` in the Connect worker properties to a value lower than `batchSize`, batch processing will be caped by `consumerMaxPollRecords` and the desired `batchSize` won’t be reached. You can also configure the connector’s underlying consumer’s `maxPollRecords` using `consumerOverrideMaxPollRecords` in the connector configuration.\n";
          type = (types.nullOr types.int);
        };
        "collectionNameFormat" = mkOption {
          description = "Default `${topic}`. Specifies a string pattern that the connector uses to construct the names of destination tables.\nWhen the property is set to `${topic}`, SGStream writes the event record to a destination table with a name that matches the name of the source topic.\nYou can also configure this property to extract values from specific fields in incoming event records and then use those values to dynamically generate the names of target tables. This ability to generate table names from values in the message source would otherwise require the use of a custom single message transformation (SMT).\nTo configure the property to dynamically generate the names of destination tables, set its value to a pattern such as `${source._field_}`. When you specify this type of pattern, the connector extracts values from the source block of the Debezium change event, and then uses those values to construct the table name. For example, you might set the value of the property to the pattern `${source.schema}_${source.table}`. Based on this pattern, if the connector reads an event in which the schema field in the source block contains the value, user, and the table field contains the value, tab, the connector writes the event record to a table with the name `user_tab`.\n";
          type = (types.nullOr types.str);
        };
        "collectionNamingStrategy" = mkOption {
          description = "**DEPRECATED** use `collectionNamingStrategy` instead. Default `io.stackgres.stream.jobs.migration.StreamMigrationTableNamingStrategy`. Specifies the fully-qualified class name of a TableNamingStrategy implementation that the connector uses to resolve table names from incoming event topic names.\nThe default behavior is to:\n* Replace the ${topic} placeholder in the `tableNameFormat` configuration property with the event’s topic.\n* Sanitize the table name by replacing dots (`.`) with underscores (`_`).\n";
          type = (types.nullOr types.str);
        };
        "columnNamingStrategy" = mkOption {
          description = "Default `io.debezium.connector.jdbc.naming.DefaultColumnNamingStrategy`. Specifies the fully-qualified class name of a ColumnNamingStrategy implementation that the connector uses to resolve column names from event field names.\nBy default, the connector uses the field name as the column name.\n";
          type = (types.nullOr types.str);
        };
        "connectionPoolAcquire_increment" = mkOption {
          description = "Default `32`. Specifies the number of connections that the connector attempts to acquire if the connection pool exceeds its maximum size.\n";
          type = (types.nullOr types.int);
        };
        "connectionPoolMax_size" = mkOption {
          description = "Default `32`. Specifies the maximum number of concurrent connections that the pool maintains.\n";
          type = (types.nullOr types.int);
        };
        "connectionPoolMin_size" = mkOption {
          description = "Default `5`. Specifies the minimum number of connections in the pool.\n";
          type = (types.nullOr types.int);
        };
        "connectionPoolTimeout" = mkOption {
          description = "Default `1800`. Specifies the number of seconds that an unused connection is kept before it is discarded.\n";
          type = (types.nullOr types.int);
        };
        "connectionUrlParameters" = mkOption {
          description = "Paremeters that are set in the JDBC connection URL. See https://jdbc.postgresql.org/documentation/use/\n";
          type = (types.nullOr types.str);
        };
        "databaseTime_zone" = mkOption {
          description = "**DEPRECATED** use `useTimeZone` instead. Default `UTC`. Specifies the timezone used when inserting JDBC temporal values.\n";
          type = (types.nullOr types.str);
        };
        "deleteEnabled" = mkOption {
          description = "Default `true`. Specifies whether the connector processes DELETE or tombstone events and removes the corresponding row from the database. Use of this option requires that you set the `primaryKeyMode` to `record_key`.\n";
          type = (types.nullOr types.bool);
        };
        "detectInsertMode" = mkOption {
          description = "Default `true`. Parameter `insertMode` is ignored and the inser mode is detected from the record hints.\n";
          type = (types.nullOr types.bool);
        };
        "dialectPostgresPostgisSchema" = mkOption {
          description = "Default `public`. Specifies the schema name where the PostgreSQL PostGIS extension is installed. The default is `public`; however, if the PostGIS extension was installed in another schema, this property should be used to specify the alternate schema name.\n";
          type = (types.nullOr types.str);
        };
        "dialectSqlserverIdentityInsert" = mkOption {
          description = "Default `false`. Specifies whether the connector automatically sets an IDENTITY_INSERT before an INSERT or UPSERT operation into the identity column of SQL Server tables, and then unsets it immediately after the operation. When the default setting (`false`) is in effect, an INSERT or UPSERT operation into the IDENTITY column of a table results in a SQL exception.\n";
          type = (types.nullOr types.bool);
        };
        "flushMaxRetries" = mkOption {
          description = "Default `5`. Specifies the maximum number of retries that the connector performs after an attempt to flush changes to the target database results in certain database errors. If the number of retries exceeds the retry value, the sink connector enters a FAILED state.\n";
          type = (types.nullOr types.int);
        };
        "flushRetryDelayMs" = mkOption {
          description = "Default `1000`. Specifies the number of milliseconds that the connector waits to retry a flush operation that failed.\n";
          type = (types.nullOr types.int);
        };
        "insertMode" = mkOption {
          description = "Default `upsert`. Specifies the strategy used to insert events into the database. The following options are available:\n* `insert`: Specifies that all events should construct INSERT-based SQL statements. Use this option only when no primary key is used, or when you can be certain that no updates can occur to rows with existing primary key values.\n* `update`: Specifies that all events should construct UPDATE-based SQL statements. Use this option only when you can be certain that the connector receives only events that apply to existing rows.\n* `upsert`: Specifies that the connector adds events to the table using upsert semantics. That is, if the primary key does not exist, the connector performs an INSERT operation, and if the key does exist, the connector performs an UPDATE operation. When idempotent writes are required, the connector should be configured to use this option.\n";
          type = (types.nullOr types.str);
        };
        "primaryKeyFields" = mkOption {
          description = "Either the name of the primary key column or a comma-separated list of fields to derive the primary key from.\nWhen `primaryKeyMode` is set to `record_key` and the event’s key is a primitive type, it is expected that this property specifies the column name to be used for the key.\nWhen the `primaryKeyMode` is set to `record_key` with a non-primitive key, or record_value, it is expected that this property specifies a comma-separated list of field names from either the key or value. If the primary.key.mode is set to record_key with a non-primitive key, or record_value, and this property is not specifies, the connector derives the primary key from all fields of either the record key or record value, depending on the specified mode.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "primaryKeyMode" = mkOption {
          description = "Default `record_key`. Specifies how the connector resolves the primary key columns from the event.\n* `none`: Specifies that no primary key columns are created.\n* `record_key`: Specifies that the primary key columns are sourced from the event’s record key. If the record key is a primitive type, the `primaryKeyFields` property is required to specify the name of the primary key column. If the record key is a struct type, the `primaryKeyFields` property is optional, and can be used to specify a subset of columns from the event’s key as the table’s primary key.\n* `record_value`: Specifies that the primary key columns is sourced from the event’s value. You can set the `primaryKeyFields` property to define the primary key as a subset of fields from the event’s value; otherwise all fields are used by default.\n";
          type = (types.nullOr types.str);
        };
        "quoteIdentifiers" = mkOption {
          description = "Default `true`. Specifies whether generated SQL statements use quotation marks to delimit table and column names. See the Quoting and case sensitivity section for more details.\n";
          type = (types.nullOr types.bool);
        };
        "removePlaceholders" = mkOption {
          description = "Default `true`. When `true` the placeholders are removed from the records.\n";
          type = (types.nullOr types.bool);
        };
        "schemaEvolution" = mkOption {
          description = "Default `basic`. Specifies how the connector evolves the destination table schemas. For more information, see Schema evolution. The following options are available:\n`none`: Specifies that the connector does not evolve the destination schema.\n`basic`: Specifies that basic evolution occurs. The connector adds missing columns to the table by comparing the incoming event’s record schema to the database table structure.\n";
          type = (types.nullOr types.str);
        };
        "tableNameFormat" = mkOption {
          description = "**DEPRECATED** use `collectionNameFormat` instead. Default `${original}`. Specifies a string that determines how the destination table name is formatted, based on the topic name of the event. The placeholder ${original} is replaced with the schema name and the table name separated by a point character (`.`).\n";
          type = (types.nullOr types.str);
        };
        "tableNamingStrategy" = mkOption {
          description = "**DEPRECATED** use `collectionNamingStrategy` instead. Default `io.stackgres.stream.jobs.migration.StreamMigrationTableNamingStrategy`. Specifies the fully-qualified class name of a TableNamingStrategy implementation that the connector uses to resolve table names from incoming event topic names.\nThe default behavior is to:\n* Replace the ${topic} placeholder in the `tableNameFormat` configuration property with the event’s topic.\n* Sanitize the table name by replacing dots (`.`) with underscores (`_`).\n";
          type = (types.nullOr types.str);
        };
        "truncateEnabled" = mkOption {
          description = "Default `true`. Specifies whether the connector processes TRUNCATE events and truncates the corresponding tables from the database.\nAlthough support for TRUNCATE statements has been available in Db2 since version 9.7, currently, the JDBC connector is unable to process standard TRUNCATE events that the Db2 connector emits.\nTo ensure that the JDBC connector can process TRUNCATE events received from Db2, perform the truncation by using an alternative to the standard TRUNCATE TABLE statement. For example:\n\n```\nALTER TABLE <table_name> ACTIVATE NOT LOGGED INITIALLY WITH EMPTY TABLE\n```\n\nThe user account that submits the preceding query requires ALTER privileges on the table to be truncated.\n";
          type = (types.nullOr types.bool);
        };
        "useReductionBuffer" = mkOption {
          description = "Specifies whether to enable the Debezium JDBC connector’s reduction buffer.\n\nChoose one of the following settings:\n\n* `false`: (default) The connector writes each change event that it consumes as a separate logical SQL change.\n* `true`: The connector uses the reduction buffer to reduce change events before it writes them to the sink database. That is, if multiple events refer to the same primary key, the connector consolidates the SQL queries and writes only a single logical SQL change, based on the row state that is reported in the most recent offset record. Choose this option to reduce the SQL load on the target database.\n\nTo optimize query processing in a PostgreSQL sink database when the reduction buffer is enabled, you must also enable the database to execute the batched queries by adding the `reWriteBatchedInserts` parameter to the JDBC connection URL.\n";
          type = (types.nullOr types.bool);
        };
        "useTimeZone" = mkOption {
          description = "Default `UTC`. Specifies the timezone used when inserting JDBC temporal values.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "batchSize" = mkOverride 1002 null;
        "collectionNameFormat" = mkOverride 1002 null;
        "collectionNamingStrategy" = mkOverride 1002 null;
        "columnNamingStrategy" = mkOverride 1002 null;
        "connectionPoolAcquire_increment" = mkOverride 1002 null;
        "connectionPoolMax_size" = mkOverride 1002 null;
        "connectionPoolMin_size" = mkOverride 1002 null;
        "connectionPoolTimeout" = mkOverride 1002 null;
        "connectionUrlParameters" = mkOverride 1002 null;
        "databaseTime_zone" = mkOverride 1002 null;
        "deleteEnabled" = mkOverride 1002 null;
        "detectInsertMode" = mkOverride 1002 null;
        "dialectPostgresPostgisSchema" = mkOverride 1002 null;
        "dialectSqlserverIdentityInsert" = mkOverride 1002 null;
        "flushMaxRetries" = mkOverride 1002 null;
        "flushRetryDelayMs" = mkOverride 1002 null;
        "insertMode" = mkOverride 1002 null;
        "primaryKeyFields" = mkOverride 1002 null;
        "primaryKeyMode" = mkOverride 1002 null;
        "quoteIdentifiers" = mkOverride 1002 null;
        "removePlaceholders" = mkOverride 1002 null;
        "schemaEvolution" = mkOverride 1002 null;
        "tableNameFormat" = mkOverride 1002 null;
        "tableNamingStrategy" = mkOverride 1002 null;
        "truncateEnabled" = mkOverride 1002 null;
        "useReductionBuffer" = mkOverride 1002 null;
        "useTimeZone" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamSpecTargetSgClusterPassword" = {

      options = {
        "key" = mkOption {
          description = "The Secret key where the password is stored.\n";
          type = types.str;
        };
        "name" = mkOption {
          description = "The Secret name where the password is stored.\n";
          type = types.str;
        };
      };

      config = { };

    };
    "stackgres.io.v1alpha1.SGStreamSpecTargetSgClusterUsername" = {

      options = {
        "key" = mkOption {
          description = "The Secret key where the username is stored.\n";
          type = types.str;
        };
        "name" = mkOption {
          description = "The Secret name where the username is stored.\n";
          type = types.str;
        };
      };

      config = { };

    };
    "stackgres.io.v1alpha1.SGStreamStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Possible conditions are:\n\n* Running: to indicate when the operation is actually running\n* Completed: to indicate when the operation has completed successfully\n* Failed: to indicate when the operation has failed\n";
          type = (types.nullOr (types.listOf (submoduleOf "stackgres.io.v1alpha1.SGStreamStatusConditions")));
        };
        "events" = mkOption {
          description = "Events status";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamStatusEvents"));
        };
        "failure" = mkOption {
          description = "The failure message";
          type = (types.nullOr types.str);
        };
        "snapshot" = mkOption {
          description = "Snapshot status";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamStatusSnapshot"));
        };
        "streaming" = mkOption {
          description = "Streaming status";
          type = (types.nullOr (submoduleOf "stackgres.io.v1alpha1.SGStreamStatusStreaming"));
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "events" = mkOverride 1002 null;
        "failure" = mkOverride 1002 null;
        "snapshot" = mkOverride 1002 null;
        "streaming" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "Last time the condition transitioned from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "A human-readable message indicating details about the transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "The reason for the condition last transition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "Status of the condition, one of `True`, `False` or `Unknown`.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "Type of deployment condition.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamStatusEvents" = {

      options = {
        "lastErrorSeen" = mkOption {
          description = "The last error seen sending events that this stream has seen since the last start or metrics reset.\n";
          type = (types.nullOr types.str);
        };
        "lastEventSent" = mkOption {
          description = "The last event that the stream has sent since the last start or metrics reset.\n";
          type = (types.nullOr types.str);
        };
        "lastEventWasSent" = mkOption {
          description = "It is true if the last event that the stream has tried to send since the last start or metrics reset was sent successfully.\n";
          type = (types.nullOr types.bool);
        };
        "totalNumberOfErrorsSeen" = mkOption {
          description = "The total number of errors sending events that this stream has seen since the last start or metrics reset.\n";
          type = (types.nullOr types.int);
        };
        "totalNumberOfEventsSent" = mkOption {
          description = "The total number of events that this stream has sent since the last start or metrics reset.\n";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "lastErrorSeen" = mkOverride 1002 null;
        "lastEventSent" = mkOverride 1002 null;
        "lastEventWasSent" = mkOverride 1002 null;
        "totalNumberOfErrorsSeen" = mkOverride 1002 null;
        "totalNumberOfEventsSent" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamStatusSnapshot" = {

      options = {
        "capturedTables" = mkOption {
          description = "The list of tables that are captured by the connector.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "chunkFrom" = mkOption {
          description = "The lower bound of the primary key set defining the current chunk.\n";
          type = (types.nullOr types.str);
        };
        "chunkId" = mkOption {
          description = "The identifier of the current snapshot chunk.\n";
          type = (types.nullOr types.str);
        };
        "chunkTo" = mkOption {
          description = "The upper bound of the primary key set defining the current chunk.\n";
          type = (types.nullOr types.str);
        };
        "currentQueueSizeInBytes" = mkOption {
          description = "The current volume, in bytes, of records in the queue.\n";
          type = (types.nullOr types.int);
        };
        "lastEvent" = mkOption {
          description = "The last snapshot event that the connector has read.\n";
          type = (types.nullOr types.str);
        };
        "maxQueueSizeInBytes" = mkOption {
          description = "The maximum buffer of the queue in bytes. This metric is available if max.queue.size.in.bytes is set to a positive long value.\n";
          type = (types.nullOr types.int);
        };
        "milliSecondsSinceLastEvent" = mkOption {
          description = "The number of milliseconds since the connector has read and processed the most recent event.\n";
          type = (types.nullOr types.int);
        };
        "numberOfEventsFiltered" = mkOption {
          description = "The number of events that have been filtered by include/exclude list filtering rules configured on the connector.\n";
          type = (types.nullOr types.int);
        };
        "queueRemainingCapacity" = mkOption {
          description = "The free capacity of the queue used to cache events from the snapshotter.\n";
          type = (types.nullOr types.int);
        };
        "queueTotalCapacity" = mkOption {
          description = "The length the queue used to cache events from the snapshotter.\n";
          type = (types.nullOr types.int);
        };
        "remainingTableCount" = mkOption {
          description = "The number of tables that the snapshot has yet to copy.\n";
          type = (types.nullOr types.int);
        };
        "rowsScanned" = mkOption {
          description = "Map containing the number of rows scanned for each table in the snapshot. Tables are incrementally added to the Map during processing. Updates every 10,000 rows scanned and upon completing a table.\n";
          type = (types.nullOr (types.attrsOf types.int));
        };
        "snapshotAborted" = mkOption {
          description = "Whether the snapshot was aborted.\n";
          type = (types.nullOr types.bool);
        };
        "snapshotCompleted" = mkOption {
          description = "Whether the snapshot completed.\n";
          type = (types.nullOr types.bool);
        };
        "snapshotDurationInSeconds" = mkOption {
          description = "The total number of seconds that the snapshot has taken so far, even if not complete. Includes also time when snapshot was paused.\n";
          type = (types.nullOr types.int);
        };
        "snapshotPaused" = mkOption {
          description = "Whether the snapshot was paused.\n";
          type = (types.nullOr types.bool);
        };
        "snapshotPausedDurationInSeconds" = mkOption {
          description = "The total number of seconds that the snapshot was paused. If the snapshot was paused several times, the paused time adds up.\n";
          type = (types.nullOr types.int);
        };
        "snapshotRunning" = mkOption {
          description = "Whether the snapshot was started.\n";
          type = (types.nullOr types.bool);
        };
        "tableFrom" = mkOption {
          description = "The lower bound of the primary key set of the currently snapshotted table.\n";
          type = (types.nullOr types.str);
        };
        "tableTo" = mkOption {
          description = "The upper bound of the primary key set of the currently snapshotted table.\n";
          type = (types.nullOr types.str);
        };
        "totalNumberOfEventsSeen" = mkOption {
          description = "The total number of events that this connector has seen since last started or reset.\n";
          type = (types.nullOr types.int);
        };
        "totalTableCount" = mkOption {
          description = "The total number of tables that are being included in the snapshot.\n";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "capturedTables" = mkOverride 1002 null;
        "chunkFrom" = mkOverride 1002 null;
        "chunkId" = mkOverride 1002 null;
        "chunkTo" = mkOverride 1002 null;
        "currentQueueSizeInBytes" = mkOverride 1002 null;
        "lastEvent" = mkOverride 1002 null;
        "maxQueueSizeInBytes" = mkOverride 1002 null;
        "milliSecondsSinceLastEvent" = mkOverride 1002 null;
        "numberOfEventsFiltered" = mkOverride 1002 null;
        "queueRemainingCapacity" = mkOverride 1002 null;
        "queueTotalCapacity" = mkOverride 1002 null;
        "remainingTableCount" = mkOverride 1002 null;
        "rowsScanned" = mkOverride 1002 null;
        "snapshotAborted" = mkOverride 1002 null;
        "snapshotCompleted" = mkOverride 1002 null;
        "snapshotDurationInSeconds" = mkOverride 1002 null;
        "snapshotPaused" = mkOverride 1002 null;
        "snapshotPausedDurationInSeconds" = mkOverride 1002 null;
        "snapshotRunning" = mkOverride 1002 null;
        "tableFrom" = mkOverride 1002 null;
        "tableTo" = mkOverride 1002 null;
        "totalNumberOfEventsSeen" = mkOverride 1002 null;
        "totalTableCount" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1alpha1.SGStreamStatusStreaming" = {

      options = {
        "capturedTables" = mkOption {
          description = "The list of tables that are captured by the connector.\n";
          type = (types.nullOr (types.listOf types.str));
        };
        "connected" = mkOption {
          description = "Flag that denotes whether the connector is currently connected to the database server.\n";
          type = (types.nullOr types.bool);
        };
        "currentQueueSizeInBytes" = mkOption {
          description = "The current volume, in bytes, of records in the queue.\n";
          type = (types.nullOr types.int);
        };
        "lastEvent" = mkOption {
          description = "The last streaming event that the connector has read.\n";
          type = (types.nullOr types.str);
        };
        "lastTransactionId" = mkOption {
          description = "Transaction identifier of the last processed transaction.\n";
          type = (types.nullOr types.str);
        };
        "maxQueueSizeInBytes" = mkOption {
          description = "The maximum buffer of the queue in bytes. This metric is available if max.queue.size.in.bytes is set to a positive long value.\n";
          type = (types.nullOr types.int);
        };
        "milliSecondsBehindSource" = mkOption {
          description = "The number of milliseconds between the last change event’s timestamp and the connector processing it. The values will incoporate any differences between the clocks on the machines where the database server and the connector are running.\n";
          type = (types.nullOr types.int);
        };
        "milliSecondsSinceLastEvent" = mkOption {
          description = "The number of milliseconds since the connector has read and processed the most recent event.\n";
          type = (types.nullOr types.int);
        };
        "numberOfCommittedTransactions" = mkOption {
          description = "The number of processed transactions that were committed.\n";
          type = (types.nullOr types.int);
        };
        "numberOfEventsFiltered" = mkOption {
          description = "The number of events that have been filtered by include/exclude list filtering rules configured on the connector.\n";
          type = (types.nullOr types.int);
        };
        "queueRemainingCapacity" = mkOption {
          description = "The free capacity of the queue used to cache events from the streamer.\n";
          type = (types.nullOr types.int);
        };
        "queueTotalCapacity" = mkOption {
          description = "The length the queue used to cache events from the streamer.\n";
          type = (types.nullOr types.int);
        };
        "sourceEventPosition" = mkOption {
          description = "The coordinates of the last received event.\n";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "totalNumberOfCreateEventsSeen" = mkOption {
          description = "The total number of create events that this connector has seen since the last start or metrics reset.\n";
          type = (types.nullOr types.int);
        };
        "totalNumberOfDeleteEventsSeen" = mkOption {
          description = "The total number of delete events that this connector has seen since the last start or metrics reset.\n";
          type = (types.nullOr types.int);
        };
        "totalNumberOfEventsSeen" = mkOption {
          description = "The total number of events that this connector has seen since the last start or metrics reset.\n";
          type = (types.nullOr types.int);
        };
        "totalNumberOfUpdateEventsSeen" = mkOption {
          description = "The total number of update events that this connector has seen since the last start or metrics reset.\n";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "capturedTables" = mkOverride 1002 null;
        "connected" = mkOverride 1002 null;
        "currentQueueSizeInBytes" = mkOverride 1002 null;
        "lastEvent" = mkOverride 1002 null;
        "lastTransactionId" = mkOverride 1002 null;
        "maxQueueSizeInBytes" = mkOverride 1002 null;
        "milliSecondsBehindSource" = mkOverride 1002 null;
        "milliSecondsSinceLastEvent" = mkOverride 1002 null;
        "numberOfCommittedTransactions" = mkOverride 1002 null;
        "numberOfEventsFiltered" = mkOverride 1002 null;
        "queueRemainingCapacity" = mkOverride 1002 null;
        "queueTotalCapacity" = mkOverride 1002 null;
        "sourceEventPosition" = mkOverride 1002 null;
        "totalNumberOfCreateEventsSeen" = mkOverride 1002 null;
        "totalNumberOfDeleteEventsSeen" = mkOverride 1002 null;
        "totalNumberOfEventsSeen" = mkOverride 1002 null;
        "totalNumberOfUpdateEventsSeen" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1beta1.SGObjectStorage" = {

      options = {
        "apiVersion" = mkOption {
          description = "\nAPIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources\n";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "\nKind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds\n";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "Object Storage configuration\n";
          type = (submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpec");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpec" = {

      options = {
        "azureBlob" = mkOption {
          description = "Azure Blob Storage configuration.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecAzureBlob"));
        };
        "encryption" = mkOption {
          description = "Section to configure object storage encryption of stored files.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecEncryption"));
        };
        "gcs" = mkOption {
          description = "Google Cloud Storage configuration.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecGcs"));
        };
        "s3" = mkOption {
          description = "Amazon Web Services S3 configuration.\n";
          type = (types.nullOr (submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecS3"));
        };
        "s3Compatible" = mkOption {
          description = "AWS S3-Compatible API configuration";
          type = (types.nullOr (submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecS3Compatible"));
        };
        "type" = mkOption {
          description = "Determine the type of object storage used for storing the base backups and WAL segments.\n      Possible values:\n      *  `s3`: Amazon Web Services S3 (Simple Storage Service).\n      *  `s3Compatible`: non-AWS services that implement a compatibility API with AWS S3.\n      *  `gcs`: Google Cloud Storage.\n      *  `azureBlob`: Microsoft Azure Blob Storage.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "azureBlob" = mkOverride 1002 null;
        "encryption" = mkOverride 1002 null;
        "gcs" = mkOverride 1002 null;
        "s3" = mkOverride 1002 null;
        "s3Compatible" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecAzureBlob" = {

      options = {
        "azureCredentials" = mkOption {
          description = "The credentials to access Azure Blob Storage for writing and reading.\n";
          type = (submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecAzureBlobAzureCredentials");
        };
        "bucket" = mkOption {
          description = "Azure Blob Storage bucket name.\n";
          type = types.str;
        };
      };

      config = { };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecAzureBlobAzureCredentials" = {

      options = {
        "secretKeySelectors" = mkOption {
          description = "Kubernetes [SecretKeySelector](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#secretkeyselector-v1-core)(s) to reference the Secret(s) that contain the information about the `azureCredentials`. . Note that you may use the same or different Secrets for the `storageAccount` and the `accessKey`. In the former case, the `keys` that identify each must be, obviously, different.\n";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecAzureBlobAzureCredentialsSecretKeySelectors"
            )
          );
        };
      };

      config = {
        "secretKeySelectors" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecAzureBlobAzureCredentialsSecretKeySelectors" = {

      options = {
        "accessKey" = mkOption {
          description = "The [storage account access key](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-keys-manage?tabs=azure-portal).\n";
          type = (
            submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecAzureBlobAzureCredentialsSecretKeySelectorsAccessKey"
          );
        };
        "storageAccount" = mkOption {
          description = "The [Storage Account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview?toc=/azure/storage/blobs/toc.json) that contains the Blob bucket to be used.\n";
          type = (
            submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecAzureBlobAzureCredentialsSecretKeySelectorsStorageAccount"
          );
        };
      };

      config = { };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecAzureBlobAzureCredentialsSecretKeySelectorsAccessKey" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from. Must be a valid secret key.\n";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).\n";
          type = types.str;
        };
      };

      config = { };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecAzureBlobAzureCredentialsSecretKeySelectorsStorageAccount" =
      {

        options = {
          "key" = mkOption {
            description = "The key of the secret to select from. Must be a valid secret key.\n";
            type = types.str;
          };
          "name" = mkOption {
            description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).\n";
            type = types.str;
          };
        };

        config = { };

      };
    "stackgres.io.v1beta1.SGObjectStorageSpecEncryption" = {

      options = {
        "method" = mkOption {
          description = "Select the storage encryption method.\n\nPossible options are:\n\n* `sodium`: will use libsodium to encrypt the files stored.\n* `openpgp`: will use OpenPGP standard to encrypt the files stored.\n\nWhen not set no encryption will be applied to stored files.\n";
          type = (types.nullOr types.str);
        };
        "openpgp" = mkOption {
          description = "OpenPGP encryption configuration.";
          type = (types.nullOr (submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecEncryptionOpenpgp"));
        };
        "sodium" = mkOption {
          description = "libsodium encryption configuration.";
          type = (types.nullOr (submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecEncryptionSodium"));
        };
      };

      config = {
        "method" = mkOverride 1002 null;
        "openpgp" = mkOverride 1002 null;
        "sodium" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecEncryptionOpenpgp" = {

      options = {
        "key" = mkOption {
          description = "To configure encryption and decryption with OpenPGP standard. You can join multiline\n key using `\\n` symbols into one line (mostly used in case of daemontools and envdir).\n";
          type = (submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecEncryptionOpenpgpKey");
        };
        "keyPassphrase" = mkOption {
          description = "If your private key is encrypted with a passphrase, you should set passphrase for decrypt.\n";
          type = (
            types.nullOr (submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecEncryptionOpenpgpKeyPassphrase")
          );
        };
      };

      config = {
        "keyPassphrase" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecEncryptionOpenpgpKey" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from. Must be a valid secret key.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecEncryptionOpenpgpKeyPassphrase" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from. Must be a valid secret key.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecEncryptionSodium" = {

      options = {
        "key" = mkOption {
          description = "To configure encryption and decryption with libsodium an algorithm that only requires\n a secret key is used. libsodium keys are fixed-size keys of 32 bytes. For optimal\n cryptographic security, it is recommened to use a random 32 byte key. To generate a\n random key, you can something like `openssl rand -hex 32` (set `keyTransform` to `hex`)\n or `openssl rand -base64 32` (set `keyTransform` to `base64`).\n";
          type = (submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecEncryptionSodiumKey");
        };
        "keyTransform" = mkOption {
          description = "The transform that will be applied to the `key` to get the required 32 byte key.\n Supported transformations are `base64`, `hex` or `none` (default). The option\n none exists for backwards compatbility, the user input will be converted to 32\n byte either via truncation or by zero-padding.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "keyTransform" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecEncryptionSodiumKey" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from. Must be a valid secret key.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecGcs" = {

      options = {
        "bucket" = mkOption {
          description = "GCS bucket name.\n";
          type = types.str;
        };
        "gcpCredentials" = mkOption {
          description = "The credentials to access GCS for writing and reading.\n";
          type = (submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecGcsGcpCredentials");
        };
      };

      config = { };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecGcsGcpCredentials" = {

      options = {
        "fetchCredentialsFromMetadataService" = mkOption {
          description = "If true, the credentials will be fetched from the GCE/GKE metadata service and the field `secretKeySelectors` have to be set to null or omitted.\n\nThis is useful when running StackGres inside a GKE cluster using [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity).\n";
          type = (types.nullOr types.bool);
        };
        "secretKeySelectors" = mkOption {
          description = "A Kubernetes [SecretKeySelector](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#secretkeyselector-v1-core) to reference the Secrets that contain the information about the Service Account to access GCS.\n";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecGcsGcpCredentialsSecretKeySelectors"
            )
          );
        };
      };

      config = {
        "fetchCredentialsFromMetadataService" = mkOverride 1002 null;
        "secretKeySelectors" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecGcsGcpCredentialsSecretKeySelectors" = {

      options = {
        "serviceAccountJSON" = mkOption {
          description = "A service account key from GCP. In JSON format, as downloaded from the GCP Console.\n";
          type = (
            submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecGcsGcpCredentialsSecretKeySelectorsServiceAccountJSON"
          );
        };
      };

      config = { };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecGcsGcpCredentialsSecretKeySelectorsServiceAccountJSON" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from. Must be a valid secret key.\n";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).\n";
          type = types.str;
        };
      };

      config = { };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecS3" = {

      options = {
        "awsCredentials" = mkOption {
          description = "The credentials to access AWS S3 for writing and reading.\n";
          type = (submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecS3AwsCredentials");
        };
        "bucket" = mkOption {
          description = "AWS S3 bucket name.\n";
          type = types.str;
        };
        "region" = mkOption {
          description = "The AWS S3 region. The Region may be detected using s3:GetBucketLocation, but if you wish to avoid giving permissions to this API call or forbid it from the applicable IAM policy, you must then specify this property.\n";
          type = (types.nullOr types.str);
        };
        "storageClass" = mkOption {
          description = "The [Amazon S3 Storage Class](https://aws.amazon.com/s3/storage-classes/) to use for the backup object storage. By default, the `STANDARD` storage class is used. Other supported values include `STANDARD_IA` for Infrequent Access and `REDUCED_REDUNDANCY`.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "region" = mkOverride 1002 null;
        "storageClass" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecS3AwsCredentials" = {

      options = {
        "secretKeySelectors" = mkOption {
          description = "Kubernetes [SecretKeySelector](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#secretkeyselector-v1-core)(s) to reference the Secrets that contain the information about the `awsCredentials`. Note that you may use the same or different Secrets for the `accessKeyId` and the `secretAccessKey`. In the former case, the `keys` that identify each must be, obviously, different.\n";
          type = (submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecS3AwsCredentialsSecretKeySelectors");
        };
      };

      config = { };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecS3AwsCredentialsSecretKeySelectors" = {

      options = {
        "accessKeyId" = mkOption {
          description = "AWS [access key ID](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys). For example, `AKIAIOSFODNN7EXAMPLE`.\n";
          type = (
            submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecS3AwsCredentialsSecretKeySelectorsAccessKeyId"
          );
        };
        "secretAccessKey" = mkOption {
          description = "AWS [secret access key](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys). For example, `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`.\n";
          type = (
            submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecS3AwsCredentialsSecretKeySelectorsSecretAccessKey"
          );
        };
      };

      config = { };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecS3AwsCredentialsSecretKeySelectorsAccessKeyId" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from. Must be a valid secret key.\n";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).\n";
          type = types.str;
        };
      };

      config = { };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecS3AwsCredentialsSecretKeySelectorsSecretAccessKey" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from. Must be a valid secret key.\n";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).\n";
          type = types.str;
        };
      };

      config = { };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecS3Compatible" = {

      options = {
        "awsCredentials" = mkOption {
          description = "The credentials to access AWS S3 for writing and reading.\n";
          type = (submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecS3CompatibleAwsCredentials");
        };
        "bucket" = mkOption {
          description = "Bucket name.\n";
          type = types.str;
        };
        "enablePathStyleAddressing" = mkOption {
          description = "Enable path-style addressing (i.e. `http://s3.amazonaws.com/BUCKET/KEY`) when connecting to an S3-compatible service that lacks support for sub-domain style bucket URLs (i.e. `http://BUCKET.s3.amazonaws.com/KEY`).\n\nDefaults to false.\n";
          type = (types.nullOr types.bool);
        };
        "endpoint" = mkOption {
          description = "Overrides the default url to connect to an S3-compatible service.\nFor example: `http://s3-like-service:9000`.\n";
          type = (types.nullOr types.str);
        };
        "region" = mkOption {
          description = "The AWS S3 region. The Region may be detected using s3:GetBucketLocation, but if you wish to avoid giving permissions to this API call or forbid it from the applicable IAM policy, you must then specify this property.\n";
          type = (types.nullOr types.str);
        };
        "storageClass" = mkOption {
          description = "The [Amazon S3 Storage Class](https://aws.amazon.com/s3/storage-classes/) to use for the backup object storage. By default, the `STANDARD` storage class is used. Other supported values include `STANDARD_IA` for Infrequent Access and `REDUCED_REDUNDANCY`.\n";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "enablePathStyleAddressing" = mkOverride 1002 null;
        "endpoint" = mkOverride 1002 null;
        "region" = mkOverride 1002 null;
        "storageClass" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecS3CompatibleAwsCredentials" = {

      options = {
        "secretKeySelectors" = mkOption {
          description = "Kubernetes [SecretKeySelector](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#secretkeyselector-v1-core)(s) to reference the Secret(s) that contain the information about the `awsCredentials`. Note that you may use the same or different Secrets for the `accessKeyId` and the `secretAccessKey`. In the former case, the `keys` that identify each must be, obviously, different.\n";
          type = (
            submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecS3CompatibleAwsCredentialsSecretKeySelectors"
          );
        };
      };

      config = { };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecS3CompatibleAwsCredentialsSecretKeySelectors" = {

      options = {
        "accessKeyId" = mkOption {
          description = "AWS [access key ID](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys). For example, `AKIAIOSFODNN7EXAMPLE`.\n";
          type = (
            submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecS3CompatibleAwsCredentialsSecretKeySelectorsAccessKeyId"
          );
        };
        "caCertificate" = mkOption {
          description = "CA Certificate file to be used when connecting to the S3 Compatible Service.\n";
          type = (
            types.nullOr (
              submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecS3CompatibleAwsCredentialsSecretKeySelectorsCaCertificate"
            )
          );
        };
        "secretAccessKey" = mkOption {
          description = "AWS [secret access key](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys). For example, `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`.\n";
          type = (
            submoduleOf "stackgres.io.v1beta1.SGObjectStorageSpecS3CompatibleAwsCredentialsSecretKeySelectorsSecretAccessKey"
          );
        };
      };

      config = {
        "caCertificate" = mkOverride 1002 null;
      };

    };
    "stackgres.io.v1beta1.SGObjectStorageSpecS3CompatibleAwsCredentialsSecretKeySelectorsAccessKeyId" =
      {

        options = {
          "key" = mkOption {
            description = "The key of the secret to select from. Must be a valid secret key.\n";
            type = types.str;
          };
          "name" = mkOption {
            description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).\n";
            type = types.str;
          };
        };

        config = { };

      };
    "stackgres.io.v1beta1.SGObjectStorageSpecS3CompatibleAwsCredentialsSecretKeySelectorsCaCertificate" =
      {

        options = {
          "key" = mkOption {
            description = "The key of the secret to select from. Must be a valid secret key.\n";
            type = types.str;
          };
          "name" = mkOption {
            description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).\n";
            type = types.str;
          };
        };

        config = { };

      };
    "stackgres.io.v1beta1.SGObjectStorageSpecS3CompatibleAwsCredentialsSecretKeySelectorsSecretAccessKey" =
      {

        options = {
          "key" = mkOption {
            description = "The key of the secret to select from. Must be a valid secret key.\n";
            type = types.str;
          };
          "name" = mkOption {
            description = "Name of the referent. [More information](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).\n";
            type = types.str;
          };
        };

        config = { };

      };

  };
in
{
  # all resource versions
  options = {
    resources = {
      "stackgres.io"."v1"."SGBackup" = mkOption {
        description = "A manual or automatically generated backup of an SGCluster configured with backups.\n\nWhen a SGBackup is created a Job will perform a full backup of the database and update the status of the SGBackup\n with the all the information required to restore it and some stats (or a failure message in case something unexpected\n happened).\nBackup generated by SGBackup are stored in the object storage configured with an SGObjectStorage together with the WAL\n files or in a [VolumeSnapshot](https://kubernetes.io/docs/concepts/storage/volume-snapshots/) (separated from the WAL files that will be still stored in an object storage)\n depending on the backup configuration of the targeted SGCluster.\nAfter an SGBackup is created the same Job performs a reconciliation of the backups by applying the retention window\n that has been configured in the SGCluster and removing the backups with managed lifecycle and the WAL files older\n than the ones that fit in the retention window. The reconciliation also removes backups (excluding WAL files) that do\n not belongs to any SGBackup (including copies). If the target storage is changed deletion of an SGBackup backups with\n managed lifecycle and the WAL files older than the ones that fit in the retention window and of backups that do not\n belongs to any SGBackup will not be performed anymore on the previous storage, only on the new target storage.\nIf the reconciliation of backups fails the backup itself do not fail and will be re-tried the next time a SGBackup\n or shecduled backup Job take place.\n";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1.SGBackup" "sgbackups" "SGBackup" "stackgres.io" "v1"
          )
        );
        default = { };
      };
      "stackgres.io"."v1"."SGConfig" = mkOption {
        description = "SGConfig stores the configuration of the StackGres Operator\n\n> **WARNING**: Creating more than one SGConfig is forbidden.\n The single SGConfig should be created automatically during installation.\n More SGConfig may exists only when allowedNamespaces or allowedNamespaceLabelSelector is used.\n";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1.SGConfig" "sgconfigs" "SGConfig" "stackgres.io" "v1"
          )
        );
        default = { };
      };
      "stackgres.io"."v1"."SGDbOps" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1.SGDbOps" "sgdbops" "SGDbOps" "stackgres.io" "v1"
          )
        );
        default = { };
      };
      "stackgres.io"."v1"."SGDistributedLogs" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1.SGDistributedLogs" "sgdistributedlogs" "SGDistributedLogs"
              "stackgres.io"
              "v1"
          )
        );
        default = { };
      };
      "stackgres.io"."v1"."SGInstanceProfile" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1.SGInstanceProfile" "sginstanceprofiles" "SGInstanceProfile"
              "stackgres.io"
              "v1"
          )
        );
        default = { };
      };
      "stackgres.io"."v1"."SGPostgresConfig" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1.SGPostgresConfig" "sgpgconfigs" "SGPostgresConfig"
              "stackgres.io"
              "v1"
          )
        );
        default = { };
      };
      "stackgres.io"."v1"."SGScript" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1.SGScript" "sgscripts" "SGScript" "stackgres.io" "v1"
          )
        );
        default = { };
      };
      "stackgres.io"."v1"."SGShardedBackup" = mkOption {
        description = "A manual or automatically generated sharded backup of an SGCluster configured with an SGBackupConfig.\n\nWhen a SGBackup is created a Job will perform a full sharded backup of the database and update the status of the SGBackup\n with the all the information required to restore it and some stats (or a failure message in case something unexpected\n happened).\nAfter an SGBackup is created the same Job performs a reconciliation of the sharded backups by applying the retention window\n that has been configured in the SGBackupConfig and removing the sharded backups with managed lifecycle and the WAL files older\n than the ones that fit in the retention window. The reconciliation also removes sharded backups (excluding WAL files) that do\n not belongs to any SGBackup. If the target storage of the SGBackupConfig is changed deletion of an SGBackup sharded backups\n with managed lifecycle and the WAL files older than the ones that fit in the retention window and of sharded backups that do\n not belongs to any SGBackup will not be performed anymore on the previous storage, only on the new target storage.\n";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1.SGShardedBackup" "sgshardedbackups" "SGShardedBackup"
              "stackgres.io"
              "v1"
          )
        );
        default = { };
      };
      "stackgres.io"."v1"."SGShardedDbOps" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1.SGShardedDbOps" "sgshardeddbops" "SGShardedDbOps"
              "stackgres.io"
              "v1"
          )
        );
        default = { };
      };
      "stackgres.io"."v1alpha1"."SGStream" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1alpha1.SGStream" "sgstreams" "SGStream" "stackgres.io"
              "v1alpha1"
          )
        );
        default = { };
      };
      "stackgres.io"."v1beta1"."SGObjectStorage" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1beta1.SGObjectStorage" "sgobjectstorages" "SGObjectStorage"
              "stackgres.io"
              "v1beta1"
          )
        );
        default = { };
      };

    }
    // {
      "sgBackups" = mkOption {
        description = "A manual or automatically generated backup of an SGCluster configured with backups.\n\nWhen a SGBackup is created a Job will perform a full backup of the database and update the status of the SGBackup\n with the all the information required to restore it and some stats (or a failure message in case something unexpected\n happened).\nBackup generated by SGBackup are stored in the object storage configured with an SGObjectStorage together with the WAL\n files or in a [VolumeSnapshot](https://kubernetes.io/docs/concepts/storage/volume-snapshots/) (separated from the WAL files that will be still stored in an object storage)\n depending on the backup configuration of the targeted SGCluster.\nAfter an SGBackup is created the same Job performs a reconciliation of the backups by applying the retention window\n that has been configured in the SGCluster and removing the backups with managed lifecycle and the WAL files older\n than the ones that fit in the retention window. The reconciliation also removes backups (excluding WAL files) that do\n not belongs to any SGBackup (including copies). If the target storage is changed deletion of an SGBackup backups with\n managed lifecycle and the WAL files older than the ones that fit in the retention window and of backups that do not\n belongs to any SGBackup will not be performed anymore on the previous storage, only on the new target storage.\nIf the reconciliation of backups fails the backup itself do not fail and will be re-tried the next time a SGBackup\n or shecduled backup Job take place.\n";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1.SGBackup" "sgbackups" "SGBackup" "stackgres.io" "v1"
          )
        );
        default = { };
      };
      "sgConfigs" = mkOption {
        description = "SGConfig stores the configuration of the StackGres Operator\n\n> **WARNING**: Creating more than one SGConfig is forbidden.\n The single SGConfig should be created automatically during installation.\n More SGConfig may exists only when allowedNamespaces or allowedNamespaceLabelSelector is used.\n";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1.SGConfig" "sgconfigs" "SGConfig" "stackgres.io" "v1"
          )
        );
        default = { };
      };
      "sgDbOps" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1.SGDbOps" "sgdbops" "SGDbOps" "stackgres.io" "v1"
          )
        );
        default = { };
      };
      "sgDistributedLogs" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1.SGDistributedLogs" "sgdistributedlogs" "SGDistributedLogs"
              "stackgres.io"
              "v1"
          )
        );
        default = { };
      };
      "sgInstanceProfiles" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1.SGInstanceProfile" "sginstanceprofiles" "SGInstanceProfile"
              "stackgres.io"
              "v1"
          )
        );
        default = { };
      };
      "sgObjectStorages" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1beta1.SGObjectStorage" "sgobjectstorages" "SGObjectStorage"
              "stackgres.io"
              "v1beta1"
          )
        );
        default = { };
      };
      "sgPgconfigs" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1.SGPostgresConfig" "sgpgconfigs" "SGPostgresConfig"
              "stackgres.io"
              "v1"
          )
        );
        default = { };
      };
      "sgScripts" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1.SGScript" "sgscripts" "SGScript" "stackgres.io" "v1"
          )
        );
        default = { };
      };
      "sgShardedBackups" = mkOption {
        description = "A manual or automatically generated sharded backup of an SGCluster configured with an SGBackupConfig.\n\nWhen a SGBackup is created a Job will perform a full sharded backup of the database and update the status of the SGBackup\n with the all the information required to restore it and some stats (or a failure message in case something unexpected\n happened).\nAfter an SGBackup is created the same Job performs a reconciliation of the sharded backups by applying the retention window\n that has been configured in the SGBackupConfig and removing the sharded backups with managed lifecycle and the WAL files older\n than the ones that fit in the retention window. The reconciliation also removes sharded backups (excluding WAL files) that do\n not belongs to any SGBackup. If the target storage of the SGBackupConfig is changed deletion of an SGBackup sharded backups\n with managed lifecycle and the WAL files older than the ones that fit in the retention window and of sharded backups that do\n not belongs to any SGBackup will not be performed anymore on the previous storage, only on the new target storage.\n";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1.SGShardedBackup" "sgshardedbackups" "SGShardedBackup"
              "stackgres.io"
              "v1"
          )
        );
        default = { };
      };
      "sgShardedDbOps" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1.SGShardedDbOps" "sgshardeddbops" "SGShardedDbOps"
              "stackgres.io"
              "v1"
          )
        );
        default = { };
      };
      "sgStreams" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "stackgres.io.v1alpha1.SGStream" "sgstreams" "SGStream" "stackgres.io"
              "v1alpha1"
          )
        );
        default = { };
      };

    };
  };

  config = {
    # expose resource definitions
    inherit definitions;

    # register resource types
    types = [
      {
        name = "sgbackups";
        group = "stackgres.io";
        version = "v1";
        kind = "SGBackup";
        attrName = "sgBackups";
      }
      {
        name = "sgconfigs";
        group = "stackgres.io";
        version = "v1";
        kind = "SGConfig";
        attrName = "sgConfigs";
      }
      {
        name = "sgdbops";
        group = "stackgres.io";
        version = "v1";
        kind = "SGDbOps";
        attrName = "sgDbOps";
      }
      {
        name = "sgdistributedlogs";
        group = "stackgres.io";
        version = "v1";
        kind = "SGDistributedLogs";
        attrName = "sgDistributedLogs";
      }
      {
        name = "sginstanceprofiles";
        group = "stackgres.io";
        version = "v1";
        kind = "SGInstanceProfile";
        attrName = "sgInstanceProfiles";
      }
      {
        name = "sgpgconfigs";
        group = "stackgres.io";
        version = "v1";
        kind = "SGPostgresConfig";
        attrName = "sgPgconfigs";
      }
      {
        name = "sgscripts";
        group = "stackgres.io";
        version = "v1";
        kind = "SGScript";
        attrName = "sgScripts";
      }
      {
        name = "sgshardedbackups";
        group = "stackgres.io";
        version = "v1";
        kind = "SGShardedBackup";
        attrName = "sgShardedBackups";
      }
      {
        name = "sgshardeddbops";
        group = "stackgres.io";
        version = "v1";
        kind = "SGShardedDbOps";
        attrName = "sgShardedDbOps";
      }
      {
        name = "sgstreams";
        group = "stackgres.io";
        version = "v1alpha1";
        kind = "SGStream";
        attrName = "sgStreams";
      }
      {
        name = "sgobjectstorages";
        group = "stackgres.io";
        version = "v1beta1";
        kind = "SGObjectStorage";
        attrName = "sgObjectStorages";
      }
    ];

    resources = {
      "stackgres.io"."v1"."SGBackup" = mkAliasDefinitions options.resources."sgBackups";
      "stackgres.io"."v1"."SGConfig" = mkAliasDefinitions options.resources."sgConfigs";
      "stackgres.io"."v1"."SGDbOps" = mkAliasDefinitions options.resources."sgDbOps";
      "stackgres.io"."v1"."SGDistributedLogs" = mkAliasDefinitions options.resources."sgDistributedLogs";
      "stackgres.io"."v1"."SGInstanceProfile" = mkAliasDefinitions options.resources."sgInstanceProfiles";
      "stackgres.io"."v1beta1"."SGObjectStorage" =
        mkAliasDefinitions
          options.resources."sgObjectStorages";
      "stackgres.io"."v1"."SGPostgresConfig" = mkAliasDefinitions options.resources."sgPgconfigs";
      "stackgres.io"."v1"."SGScript" = mkAliasDefinitions options.resources."sgScripts";
      "stackgres.io"."v1"."SGShardedBackup" = mkAliasDefinitions options.resources."sgShardedBackups";
      "stackgres.io"."v1"."SGShardedDbOps" = mkAliasDefinitions options.resources."sgShardedDbOps";
      "stackgres.io"."v1alpha1"."SGStream" = mkAliasDefinitions options.resources."sgStreams";

    };

    # make all namespaced resources default to the
    # application's namespace
    defaults = [
      {
        group = "stackgres.io";
        version = "v1";
        kind = "SGBackup";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "stackgres.io";
        version = "v1";
        kind = "SGConfig";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "stackgres.io";
        version = "v1";
        kind = "SGDbOps";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "stackgres.io";
        version = "v1";
        kind = "SGDistributedLogs";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "stackgres.io";
        version = "v1";
        kind = "SGInstanceProfile";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "stackgres.io";
        version = "v1";
        kind = "SGPostgresConfig";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "stackgres.io";
        version = "v1";
        kind = "SGScript";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "stackgres.io";
        version = "v1";
        kind = "SGShardedBackup";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "stackgres.io";
        version = "v1";
        kind = "SGShardedDbOps";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "stackgres.io";
        version = "v1alpha1";
        kind = "SGStream";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "stackgres.io";
        version = "v1beta1";
        kind = "SGObjectStorage";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
    ];
  };
}
