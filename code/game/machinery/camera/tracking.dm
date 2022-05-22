/proc/near_camera(mob/living/M)
	if (!isturf(M.loc))
		return FALSE
	if(!GLOB.cameranet.checkCameraVis(M))
		return FALSE
	return TRUE

/proc/camera_sort(list/L)
	var/obj/machinery/camera/a
	var/obj/machinery/camera/b

	for (var/i = L.len, i > 0, i--)
		for (var/j = 1 to i - 1)
			a = L[j]
			b = L[j + 1]
			if (sorttext(a.c_tag, b.c_tag) < 0)
				L.Swap(j, j + 1)
	return L
