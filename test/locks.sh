SLEEPTIME=5

set -e
. common.sh
. ${SCRIPTPREFIX}/common.sh
set +e

# Acquire TEST
{
	time=$(clock -monotonic)
	lock_acquire TEST ${SLEEPTIME}
	assert 0 $? "lock_acquire failed"
	nowtime=$(clock -monotonic)
	elapsed=$((${nowtime} - ${time}))
	if [ ${elapsed} -ge ${SLEEPTIME} ]; then
		result=slept
	else
		result=nowait
	fi
	assert nowait ${result} "lock_acquire(TEST) should not have slept, elapsed: ${elapsed}"

	lock_have TEST
	assert 0 $? "lock_have(TEST) should be true"
}

# Acquire second lock TEST2
{
	lock_have TEST2
	assert 1 $? "lock_have(TEST2) should be false"

	time=$(clock -monotonic)
	lock_acquire TEST2 ${SLEEPTIME}
	assert 0 $? "lock_acquire failed"
	nowtime=$(clock -monotonic)
	elapsed=$((${nowtime} - ${time}))
	if [ ${elapsed} -ge ${SLEEPTIME} ]; then
		result=slept
	else
		result=nowait
	fi
	assert nowait ${result} "lock_acquire(TEST2) should not have slept, elapsed: ${elapsed}"
}

# Ensure TEST is held
# XXX: Recursion is allowed now
false &&
{
	time=$(clock -monotonic)
	lock_acquire TEST ${SLEEPTIME}
	assert 1 $? "lock TEST acquired but should be held"
	nowtime=$(clock -monotonic)
	elapsed=$((${nowtime} - ${time}))
	if [ ${elapsed} -ge ${SLEEPTIME} ]; then
		result=slept
	else
		result=nowait
	fi
	assert slept ${result} "lock_acquire(TEST) should have slept, elapsed: ${elapsed}"

	lock_have TEST
	assert 0 $? "lock_have(TEST) should be true"
}

# Release TEST, but releasing return status is unreliable.
{
	lock_release TEST
	assert 0 $? "lock_release(TEST) did not succeed"
	lock_have TEST
	assert 1 $? "lock_have(TEST) should be false"
	lock_have TEST2
	assert 0 $? "lock_have(TEST2) should be true"
}

# Reacquire TEST to ensure it was released
{
	time=$(clock -monotonic)
	lock_acquire TEST ${SLEEPTIME}
	assert 0 $? "lock_acquire failed"
	nowtime=$(clock -monotonic)
	elapsed=$((${nowtime} - ${time}))
	if [ ${elapsed} -ge ${SLEEPTIME} ]; then
		result=slept
	else
		result=nowait
	fi
	assert nowait ${result} "lock_acquire(TEST) should not have slept, elapsed: ${elapsed}"
}

{
	lock_release TEST2
	assert 0 $? "lock_release(TEST2) did not succeed"
}

# Reacquire TEST2 to ensure it was released
{
	time=$(clock -monotonic)
	lock_acquire TEST2 ${SLEEPTIME}
	assert 0 $? "lock_acquire failed"
	nowtime=$(clock -monotonic)
	elapsed=$((${nowtime} - ${time}))
	if [ ${elapsed} -ge ${SLEEPTIME} ]; then
		result=slept
	else
		result=nowait
	fi
	assert nowait ${result} "lock_acquire(TEST2) should not have slept, elapsed: ${elapsed}"
}

{
	lock_release TEST
	assert 0 $? "lock_release(TEST) did not succeed"
}

{
	lock_release TEST2
	assert 0 $? "lock_release(TEST2) did not succeed"
}

# Recursive test
{
	lock_acquire TEST ${SLEEPTIME}
	assert 0 $? "$0:$LINENO: lock_acquire(TEST) did not succeed"
	lock_acquire TEST ${SLEEPTIME}
	assert 0 $? "$0:$LINENO: lock_acquire(TEST) did not succeed recursively"
	lock_release TEST
	assert 0 $? "$0:$LINENO: lock_release(TEST) did not succeed recursively"
	lock_release TEST
	assert 0 $? "$0:$LINENO: lock_release(TEST) did not succeed"
}
