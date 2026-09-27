use crate::commands::job::cli::{JobCommands, JobType};
use crate::commands::job::{decrypt_files, email_sync};
use crate::core::observability::Observable as _;

pub fn dispatch(command: JobCommands) -> i32 {
    match command {
        JobCommands::Run(run_args) => {
            let name = run_args.job_type.command_name();
            crate::observability::run_instrumented(name, move || match run_args.job_type {
                JobType::EmailSync {
                    identities,
                    local_output,
                    remote_output,
                    encryption_key,
                    concurrency,
                    max_connections_per_identity,
                    yes,
                } => email_sync::wizard::dispatch(
                    identities,
                    local_output,
                    remote_output,
                    encryption_key,
                    concurrency,
                    max_connections_per_identity,
                    yes,
                ),
                JobType::DecryptFiles {
                    input_dir,
                    output_dir,
                    encryption_key,
                    concurrency,
                    yes,
                } => decrypt_files::wizard::dispatch(
                    input_dir,
                    output_dir,
                    encryption_key,
                    concurrency,
                    yes,
                ),
            })
        }
    }
}
