import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Verify caller is authenticated and is admin
    const userClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: userError } = await userClient.auth.getUser()
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { data: profile } = await userClient
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    if (!profile || profile.role !== 'admin') {
      return new Response(JSON.stringify({ error: 'Only admins can invite staff.' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { email, full_name, role } = await req.json()

    if (!email || !full_name || !role) {
      return new Response(JSON.stringify({ error: 'email, full_name, and role are required.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Admin client with service role — can create/invite users
    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      { auth: { autoRefreshToken: false, persistSession: false } }
    )

    // Try to invite the user (sends an email invite with a set-password link)
    const { data: inviteData, error: inviteError } = await adminClient.auth.admin.inviteUserByEmail(email, {
      data: { full_name },
    })

    let userId: string

    if (inviteError) {
      // If user already exists in Auth, just find their ID and update profile
      const alreadyExists =
        inviteError.message?.toLowerCase().includes('already been registered') ||
        inviteError.message?.toLowerCase().includes('already exists') ||
        inviteError.code === 'email_exists'

      if (alreadyExists) {
        // List users to find existing user ID by email
        const { data: usersData, error: listError } = await adminClient.auth.admin.listUsers({ perPage: 1000 })
        if (listError) throw listError

        const existing = usersData?.users.find((u) => u.email?.toLowerCase() === email.toLowerCase())
        if (!existing) throw new Error(`Could not locate existing user for ${email}`)

        userId = existing.id
      } else {
        throw inviteError
      }
    } else {
      userId = inviteData.user.id
    }

    // Upsert the profile row (creates it if first time, updates if already exists)
    const { error: profileError } = await adminClient
      .from('profiles')
      .upsert({ id: userId, full_name, role }, { onConflict: 'id' })

    if (profileError) throw profileError

    const wasExisting = !!inviteError
    return new Response(
      JSON.stringify({
        success: true,
        invited: !wasExisting,
        message: wasExisting
          ? `${full_name} already has an account — their role has been updated.`
          : `Invite email sent to ${email}. They can set their password from the link.`,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err)
    return new Response(JSON.stringify({ error: message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
