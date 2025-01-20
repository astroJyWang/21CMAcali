--[[
 This is the MWA AOFlagger strategy, version 2021-03-30
 Author: André Offringa
]]

aoflagger.require_min_version("3.0")

function execute(input)
  --
  -- Generic settings
  --

  -- What polarizations to flag? Default: input:get_polarizations() (=all that are in the input data)
  -- Other options are e.g.:
  -- { 'XY', 'YX' } to flag only XY and YX, or
  -- { 'I', 'Q' } to flag only on Stokes I and Q
  local flag_polarizations = input:get_polarizations()

  local base_threshold = 1.0 -- lower means more sensitive detection
  -- How to flag complex values, options are: phase, amplitude, real, imaginary, complex
  -- May have multiple values to perform detection multiple times
  local flag_representations = { "amplitude" }
  local iteration_count = 3 -- how many iterations to perform?
  local threshold_factor_step = 2.0 -- How much to increase the sensitivity each iteration?
  -- If the following variable is true, the strategy will consider existing flags
  -- as bad data. It will exclude flagged data from detection, and make sure that any existing
  -- flags on input will be flagged on output. If set to false, existing flags are ignored.
  local use_input_flags = true
  local frequency_resize_factor = 3 -- Amount of "extra" smoothing in frequency direction
  local transient_threshold_factor = 1 -- decreasing this value makes detection of transient RFI more aggressive

  --
  -- End of generic settings
  --

  local inpPolarizations = input:get_polarizations()

  local copy_of_input
  if use_input_flags then
    -- For collecting statistics
    copy_of_input = input:copy()
  else
    input:clear_mask()
  end

  for ipol, polarization in ipairs(flag_polarizations) do
    local pol_data = input:convert_to_polarization(polarization)
    local data
    local original_data

    for _, representation in ipairs(flag_representations) do
      data = pol_data:convert_to_complex(representation)
      original_data = data:copy()

      for i = 1, iteration_count - 1 do
        local threshold_factor = threshold_factor_step ^ (iteration_count - i)

        local sumthr_level = threshold_factor * base_threshold
        if use_input_flags then
          aoflagger.sumthreshold_masked(
            data,
            original_data,
            sumthr_level,
            sumthr_level * transient_threshold_factor,
            true,
            true
          )
        else
          aoflagger.sumthreshold(data, sumthr_level, sumthr_level * transient_threshold_factor, true, true)
        end

        -- Do timestep & channel flagging
        local chdata = data:copy()
        aoflagger.threshold_timestep_rms(data, 3.5)
        aoflagger.threshold_channel_rms(chdata, 3.0 * threshold_factor, true)
        data:join_mask(chdata)

        -- High pass filtering steps
        data:set_visibilities(original_data)
        if use_input_flags then
          data:join_mask(original_data)
        end

        local resized_data = aoflagger.downsample(data, 3, frequency_resize_factor, false)
        aoflagger.low_pass_filter(resized_data, 21, 31, 2.5, 5.0)
        aoflagger.upsample(resized_data, data, 3, frequency_resize_factor)

        -- In case this script is run from inside rfigui, calling
        -- the following visualize function will add the current result
        -- to the list of displayable visualizations.
        -- If the script is not running inside rfigui, the call is ignored.
        aoflagger.visualize(data, "Fit #" .. i, i - 1)

        local tmp = original_data - data
        tmp:set_mask(data)
        data = tmp

        aoflagger.visualize(data, "Residual #" .. i, i + iteration_count)
        aoflagger.set_progress((ipol - 1) * iteration_count + i, #flag_polarizations * iteration_count)
      end -- end of iterations

      aoflagger.normalize_subbands(data, 48)

      if use_input_flags then
        aoflagger.sumthreshold_masked(
          data,
          original_data,
          base_threshold,
          base_threshold * transient_threshold_factor,
          true,
          true
        )
      else
        aoflagger.sumthreshold(data, base_threshold, base_threshold * transient_threshold_factor, true, true)
      end
    end -- end of complex representation iteration

    if use_input_flags then
      data:join_mask(original_data)
    end

    -- Helper function used below
    function contains(arr, val)
      for _, v in ipairs(arr) do
        if v == val then
          return true
        end
      end
      return false
    end

    if contains(inpPolarizations, polarization) then
      if input:is_complex() then
        data = data:convert_to_complex("complex")
      end
      input:set_polarization_data(polarization, data)
    else
      input:join_mask(data)
    end

    aoflagger.visualize(data, "Residual #" .. iteration_count, 2 * iteration_count)
    aoflagger.set_progress(ipol, #flag_polarizations)
  end -- end of polarization iterations

  if use_input_flags then
    aoflagger.scale_invariant_rank_operator_masked(input, copy_of_input, 0.2, 0.2)
  else
    aoflagger.scale_invariant_rank_operator(input, 0.2, 0.2)
  end

  aoflagger.threshold_timestep_rms(input, 4.0)
end
