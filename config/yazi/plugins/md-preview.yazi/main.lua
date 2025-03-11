local M = {}

function M:peek(job)
	local child, err = Command("glow"):arg(tostring(job.file.url)):stdout(Command.PIPED):spawn()
	if not child then
		return ya.err("spawn `glow` command failed: " .. err)
	end

	-- Skip the first line which is the archive file itself
	local _, e = child:read_line()
	if e == 1 then
		return
	end

	local limit = job.area.h
	local i, lines = 0, {}
	repeat
		local line, event = child:read_line()
		if event ~= 0 then
			break
		end

		i = i + 1
		if i > job.skip then
			table.insert(lines, line)
		end
	until i >= job.skip + limit

	child:start_kill()
	if job.skip > 0 and i < job.skip + limit then
		ya.mgr_emit("peek", { math.max(0, i - limit), only_if = job.file.url, upper_bound = true })
	else
		ya.preview_widgets(job, { ui.Text(lines):area(job.area) })
	end
end

function M:seek(job) end

return M
